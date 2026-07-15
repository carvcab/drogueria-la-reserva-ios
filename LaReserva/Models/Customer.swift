import Foundation

struct Customer: Identifiable, Codable, Hashable {
    var id: String?
    var name: String
    var cedula: String
    var phone: String
    var address: String
    var allowCredit: Bool
    var creditLimit: Double
    var balance: Double
}
