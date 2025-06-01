import Foundation
import HealthKit

class AutoSyncOperation: Operation {
    private let healthDataReader: HealthDataReader
    private let observationUploader: ObservationUploader
    private let syncedSampleRepo: SyncedSampleRepository
    private let historySampleRepo: HistorySampleRepository
    private let syncPreferences: SyncPreferences

    init(
        healthDataReader: HealthDataReader,
        observationUploader: ObservationUploader,
        syncedSampleRepo: SyncedSampleRepository,
        historySampleRepo: HistorySampleRepository,
        syncPreferences: SyncPreferences
    ) {
        self.healthDataReader = healthDataReader
        self.observationUploader = observationUploader
        self.syncedSampleRepo = syncedSampleRepo
        self.historySampleRepo = historySampleRepo
        self.syncPreferences = syncPreferences
    }

    override func main() {
        guard !isCancelled else {
            print("AutoSyncOperation cancelled before starting.")
            return
        }

        guard syncPreferences.autoSyncFrequencyValue > 0 else {
            print("Auto-sync disabled by preferences.")
            return
        }

        let selectedTypes = syncPreferences.autoSyncTypesValue
        let allowDuplicates = syncPreferences.allowDuplicatesValue
        guard !selectedTypes.isEmpty else {
            print("No auto-sync data types selected.")
            return
        }

        let end = Date()
        let start = Self.getStartDate(from: syncPreferences.autoSyncFrequencyValue, end: end)

        for type in selectedTypes {
            guard !isCancelled else {
                print("AutoSyncOperation cancelled during processing.")
                return
            }

            guard let obsType = ObservationType(rawValue: type) else {
                print("Invalid observation type: \(type)")
                continue
            }

            print("Fetching HealthKit samples for: \(type)")
            let samples = awaitResult {
                await self.healthDataReader.getIntervalSamples(
                    type: type,
                    from: start,
                    to: end
                )
            }
            print("Fetched \(samples.count) samples for type: \(type)")

            let sentCount = try? awaitResultThrowing {
                try await self.observationUploader.sendObservationsFromSamples(
                    type: obsType,
                    samples: samples,
                    syncedSampleRepository: self.syncedSampleRepo,
                    allowDuplicates: allowDuplicates
                )
            }

            if let count = sentCount, count > 0 {
                print("Uploaded \(count) observations for \(type)")

                let history = HistorySample(
                    timestamp: Date(),
                    dataType: type,
                    dataPointCount: count,
                    periodStart: start,
                    periodEnd: end,
                    source: "Auto-Sync"
                )

                try? awaitResultThrowing {
                    try await self.historySampleRepo.insert(history)
                }

                print("History record saved for \(type)")
            } else {
                print("No data uploaded for \(type)")
            }
        }

        print("AutoSyncOperation completed.")
    }

    private static func getStartDate(from frequency: Int, end: Date) -> Date {
        switch frequency {
        case 1: return Calendar.current.date(byAdding: .minute, value: -15, to: end) ?? end
        case 2: return Calendar.current.date(byAdding: .hour, value: -1, to: end) ?? end
        case 3: return Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        case 4: return Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
        case 5: return Calendar.current.date(byAdding: .month, value: -1, to: end) ?? end
        default: return Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        }
    }

    private func awaitResult<T>(_ block: @Sendable @escaping () async -> T) -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var result: T!
        Task {
            result = await block()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    private func awaitResultThrowing<T>(_ block: @Sendable @escaping () async throws -> T) throws -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<T, Error>!

        Task {
            do {
                let value = try await block()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        semaphore.wait()
        return try result.get()
    }
}
