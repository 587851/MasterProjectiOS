import SwiftUI
import SwiftData

@main
struct YourApp: App {
    let deps = DependencyProvider()

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate: AppDelegate

    let container: ModelContainer
    let context: ModelContext

    init() {
        self.container = try! ModelContainer(for: HistorySample.self, SyncedSample.self)
        self.context = container.mainContext

        let autoSyncManager = deps.makeAutoSyncManager(context: context)
        AppDelegate.autoSyncManager = autoSyncManager

        let startup = StartupViewModel(
            syncPreferences: deps.syncPreferences,
            syncedSampleRepository: deps.makeSyncedSampleRepository(context: context)
        )

        Task {
            await startup.onAppStart()
        }
    }


    var body: some Scene {
        WindowGroup {
            AppEntryView(deps: deps)
        }
        .modelContainer(for: [HistorySample.self, SyncedSample.self])
    }

}

