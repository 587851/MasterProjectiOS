import Foundation

struct PatientInfo {
    let givenName: String
    let familyName: String
    let externalID: String?
}

extension PatientInfo: Identifiable {
    var id: String {
        self.externalID ?? UUID().uuidString
    }
}
