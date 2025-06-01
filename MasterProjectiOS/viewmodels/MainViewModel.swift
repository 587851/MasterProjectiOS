import Foundation
import HealthKit
import SwiftUI
import Combine

@MainActor
class MainViewModel: ObservableObject {

    private let healthDataReader: HealthDataReader
    private let observationUploader: ObservationUploader
    private let permissionManager: HealthPermissionManager
    private let historySampleRepository: HistorySampleRepository
    private let syncedSampleRepository: SyncedSampleRepository
    private let syncPreferences: SyncPreferences

    init(
        healthDataReader: HealthDataReader,
        observationUploader: ObservationUploader,
        permissionManager: HealthPermissionManager,
        historySampleRepository: HistorySampleRepository,
        syncedSampleRepository: SyncedSampleRepository,
        syncPreferences: SyncPreferences
    ) {
        self.healthDataReader = healthDataReader
        self.observationUploader = observationUploader
        self.permissionManager = permissionManager
        self.historySampleRepository = historySampleRepository
        self.syncedSampleRepository = syncedSampleRepository
        self.syncPreferences = syncPreferences
    }

    enum DisplayMode { case text, bar, graph }

    @Published var selectedType: String = "Heart Rate"
    @Published var selectedTime: String = "Last week"
    @Published var displayText: String = ""
    @Published var isLoading: Bool = false
    @Published var chartData: [HealthDataPoint] = []
    @Published var displayMode: DisplayMode = .text

    let types = [
        "Basal Body Temperature", "Basal Metabolic Rate", "Body Fat", "Body Temperature",
        "Distance", "Heart Rate", "Heart Rate Variability",
        "Oxygen Saturation", "Respiratory Rate", "Resting Heart Rate", "Sleep",
        "Steps", "VO2 Max"
    ]

    let timeOptions = ["Last week", "Last 24 hours", "Last month"]

    private let observationTypeMap: [String: ObservationType] = [
        "Basal Body Temperature": .basalBodyTemperature,
        "Basal Metabolic Rate": .basalMetabolicRate,
        "Body Fat": .bodyFat,
        "Body Temperature": .bodyTemperature,
        "Distance": .distance,
        "Heart Rate": .heartRate,
        "Heart Rate Variability": .heartRateVariability,
        "Oxygen Saturation": .oxygenSaturation,
        "Respiratory Rate": .respiratoryRate,
        "Resting Heart Rate": .restingHeartRate,
        "Sleep": .sleep,
        "Steps": .steps,
        "VO2 Max": .vo2Max
    ]


    func readHealthDataForSelectedPeriod() async {
        let observationType = selectedType

        await withPermissionForSelectedType(type: observationType) {
            let (start, end) = self.getStartEndFromOption(selected: self.selectedTime)

            let samples = await self.healthDataReader.getIntervalSamples(type: observationType, from: start, to: end)
            let parsedData = self.healthDataReader.convertToDataPoints(samples: samples)

            self.chartData = parsedData

            let startStr = self.format(date: start)
            let endStr = self.format(date: end)
            let header = "\(observationType) data from \(startStr) to \(endStr)\n\n"
            let resultText = self.healthDataReader.convertToString(samples: samples)

            self.displayText = resultText.isEmpty
                ? "\(observationType): No data found from \(startStr) to \(endStr)."
                : header + resultText
        }
    }

    func sendHealthDataForSelectedPeriod() async {
        let selectedType = self.selectedType

        await self.withPermissionForSelectedType(type: selectedType) {
            self.isLoading = true
            defer { self.isLoading = false }

            do {
                let selectedTime = self.selectedTime
                guard let obsType = self.observationTypeMap[selectedType] else {
                    print("Unknown observation type: \(selectedType)")
                    return
                }

                let (start, end) = self.getStartEndFromOption(selected: selectedTime)

                let samples = await self.healthDataReader.getIntervalSamples(type: selectedType, from: start, to: end)
                let allowDuplicates = self.syncPreferences.allowDuplicatesValue
                
                let sentCount = try await self.observationUploader.sendObservationsFromSamples(
                    type: obsType,
                    samples: samples,
                    syncedSampleRepository: self.syncedSampleRepository,
                    allowDuplicates: allowDuplicates
                )

                let message = """
                Data sent to server successfully
                Type: \(selectedType)
                Samples sent: \(sentCount)
                Period: \(self.format(date: start)) to \(self.format(date: end))
                """

                self.displayText = message

                if sentCount > 0 {
                    let sample = HistorySample(
                        timestamp: Date(),
                        dataType: selectedType,
                        dataPointCount: sentCount,
                        periodStart: start,
                        periodEnd: end,
                        source: "Manual"
                    )

                    try await self.historySampleRepository.insert(sample)
                }

            } catch {
                print("Error while sending health data: \(error)")
                self.displayText = "Failed to send data: \(error.localizedDescription)"
            }
        }

    }

    func updateDisplayMode(to mode: DisplayMode) {
        displayMode = mode
    }

    private func withPermissionForSelectedType(type: String, action: @escaping () async -> Void) async {
        let granted = await permissionManager.withPermission(for: type, action: action)

        if !granted {
            await MainActor.run {
                self.displayText = "Access to '\(type)' not granted or no data available."
                self.chartData = []
            }
        }
    }



    private func getStartEndFromOption(selected: String) -> (Date, Date) {
        let end = Date()
        let start: Date
        switch selected {
        case "Last 24 hours":
            start = Calendar.current.date(byAdding: .day, value: -1, to: end)!
        case "Last month":
            start = Calendar.current.date(byAdding: .day, value: -30, to: end)!
        default:
            start = Calendar.current.date(byAdding: .day, value: -7, to: end)!
        }
        return (start, end)
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
