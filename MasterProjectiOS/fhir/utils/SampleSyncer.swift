import HealthKit

class SampleSyncer: ISampleSyncer {
    private let repo: SyncedSampleRepository

    init(repo: SyncedSampleRepository) {
        self.repo = repo
    }

    func syncSamples(_ samples: [HKSample]) async throws -> [SyncedSample] {
        let synced = samples.compactMap { sample in
            let id = sample.uuid.uuidString
            let measuredAt = sample.startDate.timeIntervalSince1970 > 0
                ? sample.startDate
                : nil

            return measuredAt.map {
                SyncedSample(sampleId: id, measuredAt: $0)
            }
        }

        try await repo.insertAll(synced)
        return synced
    }
}


