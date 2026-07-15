import Foundation
import FirebaseFirestore

struct CashWithdrawal: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    @FlexDouble var amount: Double
    var reason: String
}

struct CashRegister: Codable {
    @FlexDouble var base: Double
    var currentStatus: String
}
