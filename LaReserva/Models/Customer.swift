import Foundation
import FirebaseFirestore

struct Customer: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var cedula: String
    var phone: String
    var address: String
    var allowCredit: Bool
    @FlexDouble var creditLimit: Double
    @FlexDouble var balance: Double
}
