import Foundation
import SwiftData
import HealthKit

class DependencyProvider {
    // Preferences
    let syncPreferences = SyncPreferences()
    let patientPreferences = PatientPreferences()
    
    // HealthKit
    let healthKitStore = HKHealthStore()
    lazy var permissionManager = HealthPermissionManager(healthStore: healthKitStore)
    let formatter = HealthDataFormatter()
    lazy var healthDataReader = HealthDataReader(healthStore: healthKitStore, formatter: formatter)
    let statusService = HealthKitStatusService()


    // FHIR
    let fhirClient = FhirClientProvider()
    let sampleMapper = SampleMapper()

    lazy var patientManager: FHIRPatientManager = {
        FHIRPatientManager(client: fhirClient, preferences: patientPreferences)
    }()

    lazy var fhirUploader: FHIRUploader = {
        FHIRUploader(client: fhirClient)
    }()


    func makeObservationUploader(context: ModelContext) -> ObservationUploader {
        ObservationUploader(
            sampleMapper: sampleMapper,
            fhirUploader: fhirUploader,
            sampleSyncer: makeSampleSyncer(context: context),
            patientManager: patientManager
        )
    }


    // Repositories
    func makeHistorySampleRepository(context: ModelContext) -> HistorySampleRepository {
        HistorySampleRepository(context: context)
    }

    func makeSyncedSampleRepository(context: ModelContext) -> SyncedSampleRepository {
        SyncedSampleRepository(context: context)
    }
    
    //AutoSync
    func makeAutoSyncManager(context: ModelContext) -> AutoSyncManager {
        return AutoSyncManager(
            healthDataReader: healthDataReader,
            observationUploader: makeObservationUploader(context: context),
            syncedSampleRepo: makeSyncedSampleRepository(context: context),
            historySampleRepo: makeHistorySampleRepository(context: context),
            syncPreferences: syncPreferences
        )
    }


    // ViewModels
    @MainActor
    func makeMainViewModel(context: ModelContext) -> MainViewModel {
        MainViewModel(
            healthDataReader: healthDataReader,
            observationUploader: makeObservationUploader(context: context),
            permissionManager: permissionManager,
            historySampleRepository: makeHistorySampleRepository(context: context),
            syncedSampleRepository: makeSyncedSampleRepository(context: context),
            syncPreferences: syncPreferences
        )
    }
    @MainActor
    func makePermissionsViewModel() -> PermissionsViewModel {
        PermissionsViewModel(
            permissionManager: permissionManager,
            statusService: statusService
        )
    }

    @MainActor
    func makeSettingsViewModel(autoSyncManager: AutoSyncManager) -> SettingsViewModel {
        SettingsViewModel(syncPreferences: syncPreferences, autoSyncManager: autoSyncManager)
    }

    @MainActor
    func makeHistoryViewModel(context: ModelContext) -> HistoryViewModel {
        let repository = makeHistorySampleRepository(context: context)
        return HistoryViewModel(repository: repository)
    }


    @MainActor
    func makePatientViewModel() -> PatientViewModel {
        PatientViewModel(patientPreferences: patientPreferences)
    }
    
    func makeSampleSyncer(context: ModelContext) -> SampleSyncer {
        let repo = makeSyncedSampleRepository(context: context)
        return SampleSyncer(repo: repo)
    }

}
