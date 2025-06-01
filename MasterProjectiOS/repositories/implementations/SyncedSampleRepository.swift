import SwiftData
import Foundation

class SyncedSampleRepository: ISyncedSampleRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getByIds(_ ids: [String]) async throws -> [String] {
        let descriptor = FetchDescriptor<SyncedSample>(
            predicate: #Predicate { ids.contains($0.sampleId) }
        )
        let matching = try context.fetch(descriptor)
        return matching.map { $0.sampleId }
    }

    func insertAll(_ samples: [SyncedSample]) async throws {
        for sample in samples {
            context.insert(sample)
        }
        try context.save()
    }

    func deleteOlderThan(_ threshold: Date) async throws {
        let descriptor = FetchDescriptor<SyncedSample>(
            predicate: #Predicate { $0.measuredAt < threshold }
        )
        let oldSamples = try context.fetch(descriptor)
        for sample in oldSamples {
            context.delete(sample)
        }
        try context.save()
    }
}

