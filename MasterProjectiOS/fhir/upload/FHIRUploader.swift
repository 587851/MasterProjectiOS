class FHIRUploader: IFHIRUploader {
    private let client: FhirClientProvider

    init(client: FhirClientProvider = FhirClientProvider.shared) {
        self.client = client
    }

    func uploadObservations(_ observations: [FHIRObservation], chunkSize: Int = 2) async throws {
        let chunks = observations.chunked(into: chunkSize)
        
        for (index, chunk) in chunks.enumerated() {
            let entries: [BundleEntry] = chunk.map { observation in
                let request = BundleEntryRequest(method: "POST", url: "Observation")
                return BundleEntry(resource: observation, request: request)
            }
            let bundle = Bundle(type: "transaction", entry: entries)

            do {
                try await client.post(bundle, resourceType: "Bundle")
                print("Uploaded bundle \(index + 1) of \(chunks.count) successfully.")
            } catch {
                print("Failed to upload bundle \(index + 1): \(error.localizedDescription)")
                throw error // Or optionally continue to the next chunk
            }
        }
    }

}

