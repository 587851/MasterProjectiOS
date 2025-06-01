import Foundation

protocol CodableResource: Codable {}
extension FHIRObservation: CodableResource {}

struct Bundle: Encodable {
    var resourceType: String = "Bundle"
    var type: String
    var entry: [BundleEntry]
}
struct BundleEntry: Encodable {
    var resource: CodableResource
    var request: BundleEntryRequest

    enum CodingKeys: String, CodingKey {
        case resource, request
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let obs = resource as? FHIRObservation {
            try container.encode(obs, forKey: .resource)
        } else {
            throw EncodingError.invalidValue(resource, .init(
                codingPath: [CodingKeys.resource],
                debugDescription: "Unsupported FHIR resource type: \(type(of: resource))"
            ))
        }

        try container.encode(request, forKey: .request)
    }
}
struct BundleEntryRequest: Codable {
    var method: String
    var url: String
}
