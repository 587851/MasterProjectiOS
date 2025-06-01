import Foundation

@MainActor
class StartupViewModel {
    private let syncPreferences: SyncPreferences
    private let syncedSampleRepository: SyncedSampleRepository

    init(
        syncPreferences: SyncPreferences,
        syncedSampleRepository: SyncedSampleRepository
    ) {
        self.syncPreferences = syncPreferences
        self.syncedSampleRepository = syncedSampleRepository
    }

    func onAppStart() async {
        await cleanupOldRecords()
    }

    private func cleanupOldRecords() async {
        let days = syncPreferences.cleanupAgeDaysValue
        guard days > 0 else { return }

        let thresholdDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
        guard let threshold = thresholdDate else { return }

        do {
            try await syncedSampleRepository.deleteOlderThan(threshold)
            print("Old records deleted up to \(threshold)")
        } catch {
            print("Failed to delete old records: \(error)")
        }
    }
}
