import Foundation
import FirebaseFirestore

struct Withdrawal: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    var productId: String
    var productName: String = ""
    var pName: String?
    var qty: Int
    var description: String = ""
    var desc: String?
    var destination: String
}

struct OwnConsumption: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    var productId: String
    var productName: String = ""
    var pName: String?
    var qty: Int
    var description: String = ""
    var desc: String?
}
