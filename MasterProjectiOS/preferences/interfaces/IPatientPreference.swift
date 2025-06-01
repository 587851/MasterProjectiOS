import Foundation
import Combine

protocol IPatientPreferences {
    var patientInfo: AnyPublisher<PatientInfo, Never> { get }
    var givenName: AnyPublisher<String?, Never> { get }
    var familyName: AnyPublisher<String?, Never> { get }

    func setPatientName(given: String, family: String)
    func setPatientGiven(_ given: String)
    func setPatientFamily(_ family: String)
    func setPatientId(_ id: String)
    func clearId()
    func clearAll()
}

