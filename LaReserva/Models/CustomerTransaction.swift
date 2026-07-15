import Foundation
import FirebaseFirestore

struct CustomerTransaction: Identifiable, Codable {
    @DocumentID var id: String?
    var customerId: String
    var date: String
    var type: String
    @FlexDouble var amount: Double
    var saleId: String?
    var notes: String
    var method: String
}
