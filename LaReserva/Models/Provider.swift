import Foundation
import FirebaseFirestore

struct Provider: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var contactName: String
    var phone: String
    var email: String
    var address: String
    var nit: String
    var notes: String
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
}
