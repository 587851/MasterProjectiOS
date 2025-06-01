import HealthKit

protocol IHealthPermissionManagerProtocol {
    func requestPermissions(completion: @escaping (Bool) -> Void)
    func requestAllPermissions() async -> Bool
    func hasPermission(for type: String) async -> Bool
    func checkPermission(for type: String) async -> Bool
    func requestPermission(for type: String) async
    func getAllPermissionStatuses() async -> [(label: String, granted: Bool)]
    func hasRealReadAccess(for type: HKSampleType) async -> Bool
    func withPermission(for type: String, action: @escaping () async -> Void) async -> Bool
}

