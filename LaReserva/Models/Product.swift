import Foundation
import FirebaseFirestore

struct Product: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var category: String
    var barcode: String
    var quantity: Double
    var unit: String
    var costPrice: Double
    var salePrice: Double
    var minStock: Double
    var providerId: String?
    var providerName: String?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    var isLowStock: Bool {
        quantity <= minStock
    }

    var isOutOfStock: Bool {
        quantity <= 0
    }
}
