import HealthKit

class HealthPermissionManager: IHealthPermissionManagerProtocol {
    let healthStore: HKHealthStore

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    let permissionMap: [String: HKObjectType] = [
        "Basal Body Temperature": HKObjectType.quantityType(forIdentifier: .basalBodyTemperature)!,
        "Basal Metabolic Rate": HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        "Body Fat": HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
        "Body Temperature": HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        "Distance": HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        "Heart Rate": HKObjectType.quantityType(forIdentifier: .heartRate)!,
        "Heart Rate Variability": HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        "Oxygen Saturation": HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        "Respiratory Rate": HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
        "Resting Heart Rate": HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        "Sleep": HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        "Steps": HKObjectType.quantityType(forIdentifier: .stepCount)!,
        "VO2 Max": HKObjectType.quantityType(forIdentifier: .vo2Max)!
    ]

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        let typesToRequest = Set(permissionMap.values)
        healthStore.requestAuthorization(toShare: [], read: typesToRequest) { success, _ in
            completion(success)
        }
    }

    func requestAllPermissions() async -> Bool {
        let typesToRequest = Set(permissionMap.values)
        let success = await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: typesToRequest) { granted, _ in
                continuation.resume(returning: granted)
            }
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        return success
    }

    func hasPermission(for type: String) async -> Bool {
        guard let sampleType = permissionMap[type] else {
            return false
        }

        let status = healthStore.authorizationStatus(for: sampleType)
        return status == .sharingAuthorized || status == .notDetermined
    }

    func checkPermission(for type: String) async -> Bool {
        return await hasPermission(for: type)
    }

    func requestPermission(for type: String) async {
        guard let objectType = permissionMap[type] else { return }

        _ = await hasRealReadAccess(for: objectType as? HKSampleType ?? HKQuantityType.quantityType(forIdentifier: .stepCount)!)

        await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: [objectType]) { _, _ in
                continuation.resume()
            }
        }
    }

    func getAllPermissionStatuses() async -> [(label: String, granted: Bool)] {
        var results: [(String, Bool)] = []

        for (label, objectType) in permissionMap {
            if let sampleType = objectType as? HKSampleType {
                let hasAccess = await hasRealReadAccess(for: sampleType)
                results.append((label, hasAccess))
            } else {
                results.append((label, false))
            }
        }

        return results.sorted { $0.0 < $1.0 }
    }


    func hasRealReadAccess(for type: HKSampleType) async -> Bool {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) { _, samples, _ in
                let count = samples?.count ?? 0
                continuation.resume(returning: count > 0)
            }

            healthStore.execute(query)
        }
    }

    func withPermission(for type: String, action: @escaping () async -> Void) async -> Bool {
        guard let objectType = permissionMap[type],
              let sampleType = objectType as? HKSampleType else {
            return false
        }

        let hasAccess = await hasRealReadAccess(for: sampleType)

        if hasAccess {
            await action()
            return true
        } else {
            await requestPermission(for: type)
            let accessAfterRequest = await hasRealReadAccess(for: sampleType)

            if accessAfterRequest {
                await action()
                return true
            } else {
                return false
            }
        }
    }
}
