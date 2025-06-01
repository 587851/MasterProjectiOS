import Foundation
import Combine

@MainActor
class PatientViewModel: ObservableObject {
    @Published var patientInfo: PatientInfo

    private let patientPreferences: PatientPreferences
    private var cancellables = Set<AnyCancellable>()

    init(patientPreferences: PatientPreferences = .shared) {
        self.patientPreferences = patientPreferences
        
        self.patientInfo = PatientInfo(
            givenName: patientPreferences.currentGivenName ?? "test",
            familyName: patientPreferences.currentFamilyName ?? "patient",
            externalID: nil
        )
        
        observePreferences()
        ensureDefaultNames()
    }

    private func observePreferences() {
        patientPreferences.patientInfo
            .receive(on: RunLoop.main)
            .sink { [weak self] info in
                self?.patientInfo = info
            }
            .store(in: &cancellables)
    }

    private func ensureDefaultNames() {
        if patientPreferences.currentGivenName == nil {
            patientPreferences.setPatientGiven("Test")
        }
        if patientPreferences.currentFamilyName == nil {
            patientPreferences.setPatientFamily("Patient")
        }
    }

    func updateName(given: String, family: String) {
        patientPreferences.setPatientGiven(given)
        patientPreferences.setPatientFamily(family)
        patientPreferences.clearId()

        patientInfo = PatientInfo(givenName: given, familyName: family, externalID: patientInfo.externalID)
    }
}

