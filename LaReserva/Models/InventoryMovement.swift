import Foundation
import FirebaseFirestore

struct InventoryMovement: Identifiable, Codable {
    @DocumentID var id: String?
    var productId: String
    var productName: String
    var type: String
    var quantity: Double
    var previousStock: Double
    var newStock: Double
    var referenceType: String
    var referenceId: String
    var notes: String
    var createdBy: String
    var branchId: String?
    var createdAt: Timestamp?
}
