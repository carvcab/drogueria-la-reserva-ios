import Foundation
import FirebaseFirestore

struct Provider: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var nit: String
    var contact: String
    var phone: String
    var email: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nit
        case contact
        case phone
        case email
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.nit = try container.decodeIfPresent(String.self, forKey: .nit) ?? ""
        self.contact = try container.decodeIfPresent(String.self, forKey: .contact) ?? ""
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(nit, forKey: .nit)
        try container.encode(contact, forKey: .contact)
        try container.encode(phone, forKey: .phone)
        try container.encode(email, forKey: .email)
    }
}
