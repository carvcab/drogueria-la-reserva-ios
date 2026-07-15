import Foundation

struct Provider: Identifiable, Codable, Hashable {
    var id: String?
    var name: String
    var nit: String
    var contact: String
    var phone: String
    var email: String
}
