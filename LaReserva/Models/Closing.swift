import Foundation
import FirebaseFirestore

struct Closing: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    @FlexDouble var expected: Double
    @FlexDouble var actual: Double
    @FlexDouble var nextBase: Double
    @FlexDouble var sentToHistorical: Double
    @FlexDouble var difference: Double
    var status: String
    var notes: String
}
