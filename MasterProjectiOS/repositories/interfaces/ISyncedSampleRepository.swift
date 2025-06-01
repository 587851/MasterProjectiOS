import Foundation

protocol ISyncedSampleRepository {
    func getByIds(_ ids: [String]) async throws -> [String]
    func insertAll(_ samples: [SyncedSample]) async throws
    func deleteOlderThan(_ threshold: Date) async throws
}

