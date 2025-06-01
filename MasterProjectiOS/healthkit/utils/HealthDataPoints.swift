import Foundation

struct HealthDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}
