import HealthKit

protocol IHealthKitStatusServiceProtocol {
    func getAvailability() -> HealthKitAvailability
}

