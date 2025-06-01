import Foundation
import HealthKit

protocol ISampleSyncer {
    func syncSamples(_ samples: [HKSample]) async throws -> [SyncedSample]
}
