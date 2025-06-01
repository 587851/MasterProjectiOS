import Foundation
import HealthKit

class HealthDataReader: IHealthDataReader {
    private let healthStore: HKHealthStore
    private let formatter: HealthDataFormatter

    init(
        healthStore: HKHealthStore,
        formatter: HealthDataFormatter
    ) {
        self.healthStore = healthStore
        self.formatter = formatter
    }

    private let quantityTypeMap: [String: HKQuantityTypeIdentifier] = [
        "Basal Body Temperature": .basalBodyTemperature,
        "Basal Metabolic Rate": .basalEnergyBurned,
        "Body Fat": .bodyFatPercentage,
        "Body Temperature": .bodyTemperature,
        "Distance": .distanceWalkingRunning,
        "Heart Rate": .heartRate,
        "Heart Rate Variability": .heartRateVariabilitySDNN,
        "Oxygen Saturation": .oxygenSaturation,
        "Respiratory Rate": .respiratoryRate,
        "Resting Heart Rate": .restingHeartRate,
        "Steps": .stepCount,
        "VO2 Max": .vo2Max
    ]

    private let categoryTypeMap: [String: HKCategoryTypeIdentifier] = [
        "Sleep": .sleepAnalysis
    ]

    func getIntervalSamples(type: String, from start: Date, to end: Date) async -> [HKSample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        if let quantityId = quantityTypeMap[type],
           let quantityType = HKObjectType.quantityType(forIdentifier: quantityId) {
            return await fetchSamples(ofType: quantityType, predicate: predicate, sortDescriptors: [sortDescriptor])
        }

        if let categoryId = categoryTypeMap[type],
           let categoryType = HKObjectType.categoryType(forIdentifier: categoryId) {
            return await fetchSamples(ofType: categoryType, predicate: predicate, sortDescriptors: [sortDescriptor])
        }

        print("Unsupported type: \(type)")
        return []
    }

    func convertToString(samples: [HKSample]) -> String {
        return formatter.formatToString(samples: samples)
    }

    func convertToDataPoints(samples: [HKSample]) -> [HealthDataPoint] {
        return formatter.formatToPoints(samples: samples)
    }

    private func fetchSamples<T: HKSample>(ofType sampleType: HKSampleType, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) async -> [T] {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sampleType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: sortDescriptors) { _, samples, error in
                guard error == nil else {
                    print("Error fetching samples: \(error!.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: samples as? [T] ?? [])
            }
            healthStore.execute(query)
        }
    }
}

