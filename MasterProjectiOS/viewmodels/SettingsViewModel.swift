import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var uiState = SettingsUiState()
    @Published var message: String? = nil
    @Published var showToast = false

    private let syncPreferences: SyncPreferences
    private let autoSyncManager: AutoSyncManager

    private var cancellables = Set<AnyCancellable>()

    init(syncPreferences: SyncPreferences, autoSyncManager: AutoSyncManager) {
        self.syncPreferences = syncPreferences
        self.autoSyncManager = autoSyncManager
        observePreferences()
    }

    private func observePreferences() {
        Publishers.CombineLatest4(
            syncPreferences.allowDuplicates,
            syncPreferences.cleanupAgeDays,
            syncPreferences.autoSyncFrequency,
            syncPreferences.autoSyncTypes
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] allow, cleanup, freq, types in
            self?.uiState = SettingsUiState(
                allowDuplicates: allow,
                cleanupAgeDays: cleanup,
                autoSyncFrequency: freq,
                autoSyncTypes: types
            )
        }
        .store(in: &cancellables)
    }

    func setAllowDuplicates(_ value: Bool) {
        syncPreferences.setAllowDuplicates(value)
    }

    func setCleanupAgeDays(_ days: Int) {
        syncPreferences.setCleanupAgeDays(days)
    }

    func setAutoSyncFrequency(_ value: Int) {
        syncPreferences.setAutoSyncFrequency(value)

        if value != 0 {
            let backgroundPermissionGranted = true // TODO: Replace with real check
            if backgroundPermissionGranted {
                autoSyncManager.scheduleAutoSync(interval: frequencyToInterval(value))
            } else {
                syncPreferences.setAutoSyncFrequency(0)
                message = "Background read permission is missing"
                showToast = true
            }
        }
    }


    func setAutoSyncTypes(_ types: Set<String>) {
        syncPreferences.setAutoSyncTypes(types)
    }
    
    private func frequencyToInterval(_ freq: Int) -> TimeInterval {
        switch freq {
        case 1: return 15 * 60
        case 2: return 60 * 60
        case 3: return 24 * 60 * 60
        case 4: return 7 * 24 * 60 * 60
        case 5: return 31 * 24 * 60 * 60
        default: return 0
        }
    }

    
}

struct SettingsUiState {
    var allowDuplicates: Bool = false
    var cleanupAgeDays: Int = 0
    var autoSyncFrequency: Int = 0
    var autoSyncTypes: Set<String> = []
}
