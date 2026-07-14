import Foundation
import FirebaseFirestore

struct SaleItem: Codable, Identifiable {
    var id: String
    var productId: String
    var productName: String
    var quantity: Double
    var unitPrice: Double
    var total: Double
}

struct Sale: Identifiable, Codable {
    @DocumentID var id: String?
    var items: [SaleItem]
    var subtotal: Double
    var discount: Double
    var total: Double
    var paymentMethod: String
    var customerId: String?
    var customerName: String?
    var cashierName: String
    var branchId: String?
    var createdAt: Timestamp?
    var notes: String
}
