import Foundation
import SwiftData

@Model
class SyncedSample {
    @Attribute(.unique) var sampleId: String
    var measuredAt: Date

    init(sampleId: String, measuredAt: Date) {
        self.sampleId = sampleId
        self.measuredAt = measuredAt
    }
}
