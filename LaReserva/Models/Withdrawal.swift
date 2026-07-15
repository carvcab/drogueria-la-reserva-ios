import Foundation
import FirebaseFirestore

struct Withdrawal: Identifiable, Codable {
    var id: String?
    var date: String
    var productId: String
    var productName: String
    var qty: Int
    var description: String
    var destination: String

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case productId
        case productName
        case pName
        case qty
        case description
        case desc
        case destination
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.productId = try container.decodeIfPresent(String.self, forKey: .productId) ?? ""
        
        self.productName = try container.decodeIfPresent(String.self, forKey: .productName) ?? 
                           container.decodeIfPresent(String.self, forKey: .pName) ?? ""
        
        self.qty = (try? container.decode(Int.self, forKey: .qty)) ?? 
                   (try? container.decode(Double.self, forKey: .qty)).map(Int.init) ?? 0
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? 
                           container.decodeIfPresent(String.self, forKey: .desc) ?? ""
        
        self.destination = try container.decodeIfPresent(String.self, forKey: .destination) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
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
        case id
        case date
        case productId
        case productName
        case pName
        case qty
        case description
        case desc
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.productId = try container.decodeIfPresent(String.self, forKey: .productId) ?? ""
        
        self.productName = try container.decodeIfPresent(String.self, forKey: .productName) ?? 
                           container.decodeIfPresent(String.self, forKey: .pName) ?? ""
        
        self.qty = (try? container.decode(Int.self, forKey: .qty)) ?? 
                   (try? container.decode(Double.self, forKey: .qty)).map(Int.init) ?? 0
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? 
                           container.decodeIfPresent(String.self, forKey: .desc) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(productId, forKey: .productId)
        try container.encode(productName, forKey: .productName)
        try container.encode(productName, forKey: .pName)
        try container.encode(qty, forKey: .qty)
        try container.encode(description, forKey: .description)
        try container.encode(description, forKey: .desc)
    }
}
