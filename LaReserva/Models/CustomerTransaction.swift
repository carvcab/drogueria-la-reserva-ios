import Foundation
import FirebaseFirestore

struct CustomerTransaction: Identifiable, Codable {
    @DocumentID var id: String?
    var customerId: String
    var date: String
    var type: String
    var amount: Double
    var saleId: String?
    var notes: String
    var method: String

    enum CodingKeys: String, CodingKey {
        case id
        case customerId
        case date
        case type
        case amount
        case saleId
        case notes
        case method
    }

    init(id: String?, customerId: String, date: String, type: String, amount: Double, saleId: String? = nil, notes: String, method: String) {
        self.id = id
        self.customerId = customerId
        self.date = date
        self.type = type
        self.amount = amount
        self.saleId = saleId
        self.notes = notes
        self.method = method
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.customerId = try container.decodeIfPresent(String.self, forKey: .customerId) ?? ""
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        self.saleId = try container.decodeIfPresent(String.self, forKey: .saleId)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.method = try container.decodeIfPresent(String.self, forKey: .method) ?? ""
        
        self.amount = (try? container.decode(Double.self, forKey: .amount)) ?? 
                      (try? container.decode(Int.self, forKey: .amount)).map(Double.init) ?? 0.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(customerId, forKey: .customerId)
        try container.encode(date, forKey: .date)
        try container.encode(type, forKey: .type)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(saleId, forKey: .saleId)
        try container.encode(notes, forKey: .notes)
        try container.encode(method, forKey: .method)
    }
}
