struct Patient: CodableResource {
    let resourceType = "Patient"
    var name: [HumanName]

    init(name: HumanName) {
        self.name = [name]
    }

    var id: String?
}

struct HumanName: Codable {
    var given: [String]
    var family: String
}

