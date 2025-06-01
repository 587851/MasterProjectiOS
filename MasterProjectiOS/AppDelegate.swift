import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    static var autoSyncManager: AutoSyncManager!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Self.autoSyncManager.registerTasks()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Self.autoSyncManager.scheduleAutoSync(interval: 3600)
    }
}
