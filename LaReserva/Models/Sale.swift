import Foundation

struct SaleItem: Identifiable, Hashable {
    var id: String { productId }
    var productId: String
    var name: String
    var qty: Int
    var price: Double
    var cost: Double
    var paidAmount: Double
}

struct Sale: Identifiable, Hashable {
    var id: String?
    var date: String
    var customerId: String
    var customerName: String
    var payment: String
    var subtotal: Double
    var total: Double
    var received: Double
    var change: Double
    var items: [SaleItem]
    var returned: Bool?

    var profit: Double {
        items.reduce(0.0) { sum, item in
            let itemCost = item.cost > 0 ? item.cost : 0
            return sum + ((item.price - itemCost) * Double(item.qty))
        }
    }
}

struct Return: Identifiable {
    var id: String?
    var date: String
    var invoiceId: String
    var items: [SaleItem]
    var total: Double
}
