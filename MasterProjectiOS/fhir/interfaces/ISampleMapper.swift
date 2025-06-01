import Foundation
import HealthKit

protocol ISampleMapper {
    func mapToObservations(
        patientId: String,
        type: ObservationType,
        sample: HKSample
    ) -> [FHIRObservation]
}

