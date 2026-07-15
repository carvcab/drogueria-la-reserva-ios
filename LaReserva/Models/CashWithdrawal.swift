import Foundation
import FirebaseFirestore

struct CashWithdrawal: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    var amount: Double
    var reason: String

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case amount
        case reason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason) ?? ""
        
        self.amount = (try? container.decode(Double.self, forKey: .amount)) ?? 
                      (try? container.decode(Int.self, forKey: .amount)).map(Double.init) ?? 0.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(amount, forKey: .amount)
        try container.encode(reason, forKey: .reason)
    }
}

struct CashRegister: Codable {
    var base: Double
    var currentStatus: String

    enum CodingKeys: String, CodingKey {
        case base
        case currentStatus
    }

    init(base: Double = 0.0, currentStatus: String = "Abierta") {
        self.base = base
        self.currentStatus = currentStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.currentStatus = try container.decodeIfPresent(String.self, forKey: .currentStatus) ?? "Abierta"
        
        self.base = (try? container.decode(Double.self, forKey: .base)) ?? 
                    (try? container.decode(Int.self, forKey: .base)).map(Double.init) ?? 0.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(base, forKey: .base)
        try container.encode(currentStatus, forKey: .currentStatus)
    }
}
