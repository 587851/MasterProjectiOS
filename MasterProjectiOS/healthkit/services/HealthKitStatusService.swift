import HealthKit

class HealthKitStatusService: IHealthKitStatusServiceProtocol {
    func getAvailability() -> HealthKitAvailability {
        if !HKHealthStore.isHealthDataAvailable() {
            return .notAvailable
        }
        return .available
    }
}

