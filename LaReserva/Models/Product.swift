import Foundation
import FirebaseFirestore

struct Product: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var category: String
    var barcode: String?
    var location: String?
    @FlexDouble var price: Double
    @FlexDouble var cost: Double
    var providerName: String?
    var alertThreshold: Int
    var stock: Int

    var isLowStock: Bool { stock <= alertThreshold }
    var isOutOfStock: Bool { stock <= 0 }
}
