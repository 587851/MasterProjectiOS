import Foundation

class FHIRPatientManager: IFHIRPatientManager {
    
    private let client: FhirClientProvider
    private let preferences: PatientPreferences
    
    init(client: FhirClientProvider = .shared, preferences: PatientPreferences = .shared) {
        self.client = client
        self.preferences = preferences
    }
    
    func getOrCreatePatientId() async throws -> String {
        let existingID = preferences.currentPatientId
        let existingNameGiven = preferences.currentGivenName
        let existingNameFamily = preferences.currentFamilyName
        
        if(existingID != nil){
            let exist = try await client.checkPatientExists(id: existingID!)
            if(exist){
                return existingID!
            } else {
                preferences.clearAll()
            }
        }
        
        let patient = Patient(
            name: HumanName(
                given: [existingNameGiven ?? "First"],
                family: existingNameFamily ?? "Last"
            )
        )
        
        let newId = try await client.createPatientAndReturnId(patient)
        preferences.setPatientId(newId)
        return newId
    }
}

