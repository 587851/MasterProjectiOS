import Foundation
import Combine

class PatientPreferences: IPatientPreferences {
    static let shared = PatientPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let patientId = "patient_id"
        static let givenName = "patient_given_name"
        static let familyName = "patient_family_name"
    }

    // Combine publishers
    private let givenNameSubject = CurrentValueSubject<String?, Never>(
        UserDefaults.standard.string(forKey: Keys.givenName)
    )
    private let familyNameSubject = CurrentValueSubject<String?, Never>(
        UserDefaults.standard.string(forKey: Keys.familyName)
    )
    private let idSubject = CurrentValueSubject<String?, Never>(
        UserDefaults.standard.string(forKey: Keys.patientId)
    )

    var givenName: AnyPublisher<String?, Never> {
        givenNameSubject.eraseToAnyPublisher()
    }

    var familyName: AnyPublisher<String?, Never> {
        familyNameSubject.eraseToAnyPublisher()
    }

    var patientInfo: AnyPublisher<PatientInfo, Never> {
        Publishers
            .CombineLatest3(givenNameSubject, familyNameSubject, idSubject)
            .map { given, family, id in
                PatientInfo(
                    givenName: given ?? "test",
                    familyName: family ?? "patient",
                    externalID: id
                )
            }
            .eraseToAnyPublisher()
    }

    var currentPatientId: String? {
        defaults.string(forKey: Keys.patientId)
    }

    var currentGivenName: String? {
        defaults.string(forKey: Keys.givenName)
    }

    var currentFamilyName: String? {
        defaults.string(forKey: Keys.familyName)
    }

    func setPatientName(given: String, family: String) {
        defaults.set(given, forKey: Keys.givenName)
        defaults.set(family, forKey: Keys.familyName)
        givenNameSubject.send(given)
        familyNameSubject.send(family)
    }

    func setPatientGiven(_ given: String) {
        defaults.set(given, forKey: Keys.givenName)
        givenNameSubject.send(given)
    }

    func setPatientFamily(_ family: String) {
        defaults.set(family, forKey: Keys.familyName)
        familyNameSubject.send(family)
    }

    func setPatientId(_ id: String) {
        defaults.set(id, forKey: Keys.patientId)
        idSubject.send(id)
    }


    func clearId() {
        defaults.removeObject(forKey: Keys.patientId)
        idSubject.send(nil)
    }

    func clearAll() {
        defaults.removeObject(forKey: Keys.patientId)
        defaults.removeObject(forKey: Keys.givenName)
        defaults.removeObject(forKey: Keys.familyName)
        givenNameSubject.send(nil)
        familyNameSubject.send(nil)
        idSubject.send(nil)
    }
}

