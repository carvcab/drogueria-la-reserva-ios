import Foundation
import FirebaseFirestore

struct Provider: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var nit: String
    var contact: String
    var phone: String
    var email: String
}
