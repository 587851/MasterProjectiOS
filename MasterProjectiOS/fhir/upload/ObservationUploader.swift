import Foundation
import HealthKit

class ObservationUploader: IObservationUploading {

    private let sampleMapper: SampleMapper
    private let fhirUploader: FHIRUploader
    private let sampleSyncer: SampleSyncer
    private let patientManager: FHIRPatientManager

    init(
        sampleMapper: SampleMapper,
        fhirUploader: FHIRUploader,
        sampleSyncer: SampleSyncer,
        patientManager: FHIRPatientManager
    ) {
        self.sampleMapper = sampleMapper
        self.fhirUploader = fhirUploader
        self.sampleSyncer = sampleSyncer
        self.patientManager = patientManager
    }

    func sendObservationsFromSamples(
        type: ObservationType,
        samples: [HKSample],
        syncedSampleRepository: SyncedSampleRepository,
        allowDuplicates: Bool
    ) async throws -> Int {
        let patientId = try await patientManager.getOrCreatePatientId()
        print(patientId)

        let newSamples: [HKSample]
        if !allowDuplicates {
            let allIds = samples.map { $0.uuid.uuidString }
            let syncedIds = try await syncedSampleRepository.getByIds(allIds)
            newSamples = samples.filter { !syncedIds.contains($0.uuid.uuidString) }
        } else {
            newSamples = samples
        }

        let observations = newSamples.flatMap {
            sampleMapper.mapToObservation(patientId: patientId, type: type, sample: $0)
        }

        if !observations.isEmpty {
            try await fhirUploader.uploadObservations(observations)
            try await sampleSyncer.syncSamples(newSamples)
        }

        return observations.count
    }

}

