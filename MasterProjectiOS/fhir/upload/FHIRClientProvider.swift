import Foundation

class FhirClientProvider: IFHIRClientProvider {
    static let shared = FhirClientProvider()

    private let baseURL: URL = {
        guard let urlString = Foundation.Bundle.main.object(forInfoDictionaryKey: "FHIRServerURL") as? String,
              let url = URL(string: urlString) else {
            fatalError("FHIRServerURL not set or invalid in Info.plist")
        }
        return url
    }()
    private let session = URLSession.shared

    func post<Resource: Encodable>(_ resource: Resource, resourceType: String) async throws {
        let url: URL
        if resourceType == "Bundle" {
            url = baseURL
        } else {
            url = baseURL.appendingPathComponent(resourceType)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(resource)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FHIR", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("FHIR upload failed")
            print("Status code: \(httpResponse.statusCode)")
            print("Response body: \(responseBody)")
            throw NSError(domain: "FHIR", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to upload resource",
                "statusCode": httpResponse.statusCode,
                "response": responseBody
            ])
        }
    }

    func checkPatientExists(id: String) async throws -> Bool {
            let url = baseURL.appendingPathComponent("Patient/\(id)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        }

    func createPatientAndReturnId(_ patient: Patient) async throws -> String {
            let url = baseURL.appendingPathComponent("Patient")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(patient)

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw NSError(domain: "FHIR", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create patient"])
            }

            if let patient = try? JSONDecoder().decode(Patient.self, from: data),
               let id = patient.id {
                return id
            }

            throw NSError(domain: "FHIR", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not extract Patient ID"])
        }

}
