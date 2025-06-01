import Foundation

protocol IFHIRUploader {
    func uploadObservations(_ observations: [FHIRObservation], chunkSize: Int) async throws
}

