import Foundation

struct CustomerTransaction: Identifiable, Codable {
    var id: String?
    var customerId: String
    var date: String
    var type: String
    var amount: Double
    var saleId: String?
    var notes: String
    var method: String
}
