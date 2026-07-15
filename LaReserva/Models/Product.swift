import Foundation

struct Product: Identifiable, Hashable {
    var id: String?
    var name: String
    var category: String
    var barcode: String?
    var location: String?
    var price: Double
    var cost: Double
    var providerName: String?
    var alertThreshold: Int
    var stock: Int

    var isLowStock: Bool { stock <= alertThreshold }
    var isOutOfStock: Bool { stock <= 0 }
}
