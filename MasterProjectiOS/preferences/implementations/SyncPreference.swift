import Foundation
import Combine

class SyncPreferences: ISyncPreferences {
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    private enum Keys {
        static let allowDuplicates = "allow_duplicates"
        static let cleanupAgeDays = "cleanup_age_days"
        static let autoSyncFrequency = "auto_sync_frequency"
        static let autoSyncTypes = "auto_sync_types"
    }

    private let allowDuplicatesSubject = CurrentValueSubject<Bool, Never>(UserDefaults.standard.bool(forKey: Keys.allowDuplicates))
    var allowDuplicates: AnyPublisher<Bool, Never> {
        allowDuplicatesSubject.eraseToAnyPublisher()
    }


    func setAllowDuplicates(_ value: Bool) {
        defaults.set(value, forKey: Keys.allowDuplicates)
        allowDuplicatesSubject.send(value)
    }

    private let cleanupAgeDaysSubject = CurrentValueSubject<Int, Never>(UserDefaults.standard.integer(forKey: Keys.cleanupAgeDays))
    var cleanupAgeDays: AnyPublisher<Int, Never> {
        cleanupAgeDaysSubject.eraseToAnyPublisher()
    }

    func setCleanupAgeDays(_ days: Int) {
        defaults.set(days, forKey: Keys.cleanupAgeDays)
        cleanupAgeDaysSubject.send(days)
    }

    private let autoSyncFrequencySubject = CurrentValueSubject<Int, Never>(UserDefaults.standard.integer(forKey: Keys.autoSyncFrequency))
    var autoSyncFrequency: AnyPublisher<Int, Never> {
        autoSyncFrequencySubject.eraseToAnyPublisher()
    }

    func setAutoSyncFrequency(_ value: Int) {
        defaults.set(value, forKey: Keys.autoSyncFrequency)
        autoSyncFrequencySubject.send(value)
    }

    private let autoSyncTypesSubject = CurrentValueSubject<Set<String>, Never>(
        Set(UserDefaults.standard.stringArray(forKey: Keys.autoSyncTypes) ?? [])
    )
    var autoSyncTypes: AnyPublisher<Set<String>, Never> {
        autoSyncTypesSubject.eraseToAnyPublisher()
    }

    func setAutoSyncTypes(_ types: Set<String>) {
        defaults.set(Array(types), forKey: Keys.autoSyncTypes)
        autoSyncTypesSubject.send(types)
    }
    
    var allowDuplicatesValue: Bool {
           defaults.bool(forKey: Keys.allowDuplicates)
    }

    var cleanupAgeDaysValue: Int {
           defaults.integer(forKey: Keys.cleanupAgeDays)
    }

    var autoSyncFrequencyValue: Int {
           defaults.integer(forKey: Keys.autoSyncFrequency)
    }

    var autoSyncTypesValue: Set<String> {
           Set(defaults.stringArray(forKey: Keys.autoSyncTypes) ?? [])
    }
    
}

