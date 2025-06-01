protocol IFHIRPatientManager {
    func getOrCreatePatientId() async throws -> String
}
