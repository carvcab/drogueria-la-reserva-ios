import Foundation
import FirebaseFirestore

struct Customer: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var cedula: String
    var phone: String
    var address: String
    var allowCredit: Bool
    var creditLimit: Double
    var balance: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case cedula
        case phone
        case address
        case allowCredit
        case creditLimit
        case balance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.cedula = try container.decodeIfPresent(String.self, forKey: .cedula) ?? ""
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        self.address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        self.allowCredit = try container.decodeIfPresent(Bool.self, forKey: .allowCredit) ?? false
        
        self.creditLimit = (try? container.decode(Double.self, forKey: .creditLimit)) ?? 
                           (try? container.decode(Int.self, forKey: .creditLimit)).map(Double.init) ?? 0.0
        
        self.balance = (try? container.decode(Double.self, forKey: .balance)) ?? 
                       (try? container.decode(Int.self, forKey: .balance)).map(Double.init) ?? 0.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(cedula, forKey: .cedula)
        try container.encode(phone, forKey: .phone)
        try container.encode(address, forKey: .address)
        try container.encode(allowCredit, forKey: .allowCredit)
        try container.encode(creditLimit, forKey: .creditLimit)
        try container.encode(balance, forKey: .balance)
    }
}
