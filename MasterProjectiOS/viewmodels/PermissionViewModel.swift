import Foundation
import HealthKit
import SwiftUI

@MainActor
class PermissionsViewModel: ObservableObject {
    @Published var readPermissions: [(String, Bool)] = []
    @Published var healthConnectStatusMessage: String? = nil
    @Published var showAllGrantedToast: Bool = false

    private let permissionManager: HealthPermissionManager
    private let statusService: HealthKitStatusService

    init(permissionManager: HealthPermissionManager, statusService: HealthKitStatusService) {
        self.permissionManager = permissionManager
        self.statusService = statusService
        refreshPermissions()
    }

    func refreshPermissions() {
        Task {
            if HKHealthStore.isHealthDataAvailable() {
                healthConnectStatusMessage = "✅ HealthKit is available."
                readPermissions = await permissionManager.getAllPermissionStatuses()
            } else {
                healthConnectStatusMessage = "❌ HealthKit is not available."
            }
        }
    }

    func requestPermissions() {
        Task {
            print("ViewModel starting requestPermissions()")
            let granted = await permissionManager.requestAllPermissions()
            await refreshPermissions()
            showAllGrantedToast = granted && readPermissions.contains { $0.1 }
        }
    }
}
