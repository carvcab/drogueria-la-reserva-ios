import Foundation

struct Withdrawal: Identifiable {
    var id: String?
    var date: String
    var productId: String
    var productName: String
    var qty: Int
    var description: String
    var destination: String
}

struct OwnConsumption: Identifiable {
    var id: String?
    var date: String
    var productId: String
    var productName: String
    var qty: Int
    var description: String
}
