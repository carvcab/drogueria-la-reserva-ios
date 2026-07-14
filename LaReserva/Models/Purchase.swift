import Foundation
import FirebaseFirestore

struct PurchaseItem: Codable, Identifiable {
    var id: String
    var productId: String
    var productName: String
    var quantity: Double
    var unitCost: Double
    var total: Double
}

struct Purchase: Identifiable, Codable {
    @DocumentID var id: String?
    var items: [PurchaseItem]
    var providerId: String?
    var providerName: String?
    var subtotal: Double
    var discount: Double
    var total: Double
    var invoiceNumber: String
    var notes: String
    var createdBy: String
    var branchId: String?
    var createdAt: Timestamp?
}
