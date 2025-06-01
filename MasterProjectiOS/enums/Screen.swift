import Foundation

enum Screen: String, CaseIterable, Identifiable {
    case main
    case history
    case settings
    case permissions

    var id: String { rawValue }

    var label: String {
        switch self {
        case .main: return "Main"
        case .history: return "History"
        case .settings: return "Settings"
        case .permissions: return "Permissions"
        }
    }

    var route: String {
        rawValue
    }
}

