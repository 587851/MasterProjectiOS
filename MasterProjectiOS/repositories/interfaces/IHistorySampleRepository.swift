import Foundation

protocol IHistorySampleRepository {
    func getAll() async throws -> [HistorySample]
    func insert(_ sample: HistorySample) async throws
    func clearAll() async throws
}
