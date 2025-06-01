import Foundation

struct PermissionInfo {
    let label: String
    let permission: String
}

extension PermissionInfo: Identifiable {
    var id: String { permission }
}

