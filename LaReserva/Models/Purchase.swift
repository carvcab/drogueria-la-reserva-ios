import Foundation

struct PurchaseLine: Identifiable {
    var id: String { productId }
    var productId: String
    var name: String
    var qty: Int
    var cost: Double
    var salePrice: Double
}

struct Purchase: Identifiable {
    var id: String?
    var date: String
    var providerName: String
    var invoiceNo: String
    var total: Double
    var lines: [PurchaseLine]
}
