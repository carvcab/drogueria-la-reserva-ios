import Foundation

struct CashWithdrawal: Identifiable {
    var id: String?
    var date: String
    var amount: Double
    var reason: String
}

struct CashRegister {
    var base: Double
    var currentStatus: String
}
