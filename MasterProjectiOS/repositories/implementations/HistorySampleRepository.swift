import SwiftData
import Foundation

class HistorySampleRepository: IHistorySampleRepository {
    
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() async throws -> [HistorySample] {
        let descriptor = FetchDescriptor<HistorySample>(
            sortBy: [SortDescriptor(\HistorySample.timestamp, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ sample: HistorySample) async throws {
        context.insert(sample)
        try context.save()
    }

    func clearAll() async throws {
        let allSamples = try await getAll()
        for sample in allSamples {
            context.delete(sample)
        }
        try context.save()
    }
    
}
