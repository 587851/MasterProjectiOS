import Foundation
import SwiftData

@Model
final class HistorySample: Identifiable, Hashable, Sendable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var dataType: String
    var dataPointCount: Int
    var periodStart: Date
    var periodEnd: Date
    var source: String

    init(
        id: UUID = UUID(),
        timestamp: Date,
        dataType: String,
        dataPointCount: Int,
        periodStart: Date,
        periodEnd: Date,
        source: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.dataType = dataType
        self.dataPointCount = dataPointCount
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.source = source
    }
}
