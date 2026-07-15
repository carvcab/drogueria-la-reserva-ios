import Foundation

struct Withdrawal: Identifiable, Codable {
    var id: String?
    var date: String
    var productId: String
    var productName: String
    var qty: Int
    var description: String
    var destination: String

    enum CodingKeys: String, CodingKey {
        case date
        case productId
        case productName
        case pName
        case qty
        case description
        case desc
        case destination
    }

    init(id: String? = nil, date: String, productId: String, productName: String, qty: Int, description: String, destination: String) {
        self.id = id
        self.date = date
        self.productId = productId
        self.productName = productName
        self.qty = qty
        self.description = description
        self.destination = destination
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = (try? container.decode(String.self, forKey: .date)) ?? ""
        self.productId = (try? container.decode(String.self, forKey: .productId)) ?? ""

        if let n = try? container.decode(String.self, forKey: .pName) {
            self.productName = n
        } else {
            self.productName = (try? container.decode(String.self, forKey: .productName)) ?? ""
        }

        if let q = try? container.decode(Int.self, forKey: .qty) {
            self.qty = q
        } else {
            self.qty = 0
        }

        if let d = try? container.decode(String.self, forKey: .desc) {
            self.description = d
        } else {
            self.description = (try? container.decode(String.self, forKey: .description)) ?? ""
        }

        self.destination = (try? container.decode(String.self, forKey: .destination)) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(productId, forKey: .productId)
        try container.encode(productName, forKey: .productName)
        try container.encode(productName, forKey: .pName)
        try container.encode(qty, forKey: .qty)
        try container.encode(description, forKey: .description)
        try container.encode(description, forKey: .desc)
        try container.encode(destination, forKey: .destination)
    }
}

struct OwnConsumption: Identifiable, Codable {
    var id: String?
    var date: String
    var productId: String
    var productName: String
    var qty: Int
    var description: String

    enum CodingKeys: String, CodingKey {
        case date
        case productId
        case productName
        case pName
        case qty
        case description
        case desc
    }

    init(id: String? = nil, date: String, productId: String, productName: String, qty: Int, description: String) {
        self.id = id
        self.date = date
        self.productId = productId
        self.productName = productName
        self.qty = qty
        self.description = description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = (try? container.decode(String.self, forKey: .date)) ?? ""
        self.productId = (try? container.decode(String.self, forKey: .productId)) ?? ""

        if let n = try? container.decode(String.self, forKey: .pName) {
            self.productName = n
        } else {
            self.productName = (try? container.decode(String.self, forKey: .productName)) ?? ""
        }

        if let q = try? container.decode(Int.self, forKey: .qty) {
            self.qty = q
        } else {
            self.qty = 0
        }

        if let d = try? container.decode(String.self, forKey: .desc) {
            self.description = d
        } else {
            self.description = (try? container.decode(String.self, forKey: .description)) ?? ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(productId, forKey: .productId)
        try container.encode(productName, forKey: .productName)
        try container.encode(productName, forKey: .pName)
        try container.encode(qty, forKey: .qty)
        try container.encode(description, forKey: .description)
        try container.encode(description, forKey: .desc)
    }
}
