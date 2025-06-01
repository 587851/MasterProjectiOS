import Foundation

struct FHIRObservation: Codable {
    var resourceType: String = "Observation"
    var status: String
    var category: [CodeableConcept]
    var code: CodeableConcept
    var valueQuantity: Quantity
    var subject: Reference?
    var effectiveDateTime: String?
    var effectivePeriod: Period?
}
struct CodeableConcept: Codable {
    var coding: [Coding]
    var text: String?
}
struct Coding: Codable {
    var system: String
    var code: String
    var display: String?
}
struct Quantity: Codable {
    var value: Double
    var unit: String
    var system: String
    var code: String
}
struct Reference: Codable {
    var reference: String
}
struct Period: Codable {
    var start: String
    var end: String
}
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: self.count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, self.count)])
        }
    }
}


