import Foundation
import Combine

protocol ISyncPreferences {
    var allowDuplicates: AnyPublisher<Bool, Never> { get }
    func setAllowDuplicates(_ value: Bool)

    var cleanupAgeDays: AnyPublisher<Int, Never> { get }
    func setCleanupAgeDays(_ days: Int)

    var autoSyncFrequency: AnyPublisher<Int, Never> { get }
    func setAutoSyncFrequency(_ value: Int)

    var autoSyncTypes: AnyPublisher<Set<String>, Never> { get }
    func setAutoSyncTypes(_ types: Set<String>)
}


