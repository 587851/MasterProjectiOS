import BackgroundTasks
import Foundation
import os.log

class AutoSyncManager {
    static let shared: AutoSyncManager = {
        fatalError("You must initialize this with dependencies using init(...)")
    }()

    private let healthDataReader: HealthDataReader
    private let observationUploader: ObservationUploader
    private let syncedSampleRepo: SyncedSampleRepository
    private let historySampleRepo: HistorySampleRepository
    private let syncPreferences: SyncPreferences

    init(
        healthDataReader: HealthDataReader,
        observationUploader: ObservationUploader,
        syncedSampleRepo: SyncedSampleRepository,
        historySampleRepo: HistorySampleRepository,
        syncPreferences: SyncPreferences
    ) {
        self.healthDataReader = healthDataReader
        self.observationUploader = observationUploader
        self.syncedSampleRepo = syncedSampleRepo
        self.historySampleRepo = historySampleRepo
        self.syncPreferences = syncPreferences
    }

    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.example.healthdata.autosync",
            using: nil
        ) { task in
            self.handleAutoSyncTask(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleAutoSync(interval: TimeInterval) {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.healthdata.autosync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        do {
            try BGTaskScheduler.shared.submit(request)
            os_log(.info, "Scheduled auto-sync in %.0f seconds", interval)
        } catch {
            os_log(.error, "Failed to schedule auto-sync: %@", error.localizedDescription)
        }
    }

    private func handleAutoSyncTask(task: BGAppRefreshTask) {
        // Reschedule auto-sync after the task is completed or expired
        scheduleAutoSync(interval: 3600) // Re-schedule every hour

        let operation = AutoSyncOperation(
            healthDataReader: healthDataReader,
            observationUploader: observationUploader,
            syncedSampleRepo: syncedSampleRepo,
            historySampleRepo: historySampleRepo,
            syncPreferences: syncPreferences
        )

        task.expirationHandler = {
            os_log(.info, "Auto-sync task expired before completion.")
            operation.cancel()
        }

        operation.completionBlock = {
            let success = !operation.isCancelled
            os_log(.info, "Auto-sync task completed: %@", success ? "success" : "cancelled")
            task.setTaskCompleted(success: success)
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperation(operation)
    }
}
