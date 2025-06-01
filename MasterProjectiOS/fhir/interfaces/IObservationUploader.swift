import Foundation
import HealthKit

protocol IObservationUploading {
    func sendObservationsFromSamples(
        type: ObservationType,
        samples: [HKSample],
        syncedSampleRepository: SyncedSampleRepository,
        allowDuplicates: Bool
    ) async throws -> Int
}

