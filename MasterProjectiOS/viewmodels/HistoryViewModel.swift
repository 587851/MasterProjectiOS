import Foundation
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var groupedRecords: [String: [HistorySample]] = [:]

    private let repository: HistorySampleRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: HistorySampleRepository) {
        self.repository = repository
        observeHistory()
    }

    private func observeHistory() {
        Task {
            do {
                let records = try await repository.getAll()
                groupedRecords = Self.groupRecords(records)
            } catch {
                print("Failed to fetch history samples: \(error)")
            }
        }
    }


    func refresh() {
        observeHistory()
    }

    private static func groupRecords(_ records: [HistorySample]) -> [String: [HistorySample]] {
        let now = Date()
        let grouped = Dictionary(grouping: records) { record -> String in
            let duration = now.timeIntervalSince(record.timestamp)
            switch duration {
            case 0..<86400: return "Last 24 Hours"
            case 86400..<604800: return "Last Week"
            default: return "Older"
            }
        }

        let desiredOrder = ["Last 24 Hours", "Last Week", "Older"]
        var sorted: [String: [HistorySample]] = [:]
        for key in desiredOrder {
            if let group = grouped[key] {
                sorted[key] = group.sorted(by: { $0.timestamp > $1.timestamp })
            }
        }

        return sorted
    }
}
