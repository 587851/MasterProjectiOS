import HealthKit

protocol IHealthDataFormatter {
    func formatToString(samples: [HKSample]) -> String
    func formatToPoints(samples: [HKSample]) -> [HealthDataPoint]
}
