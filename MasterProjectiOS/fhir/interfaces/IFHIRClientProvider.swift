import Foundation

protocol IFHIRClientProvider {
    func post<Resource: Encodable>(_ resource: Resource, resourceType: String) async throws
    func checkPatientExists(id: String) async throws -> Bool
    func createPatientAndReturnId(_ patient: Patient) async throws -> String
}


