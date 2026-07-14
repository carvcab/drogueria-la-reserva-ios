import Foundation
import FirebaseFirestore

struct Customer: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var phone: String
    var email: String
    var address: String
    var documentType: String
    var documentNumber: String
    var creditLimit: Double
    var currentBalance: Double
    var notes: String
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
}
