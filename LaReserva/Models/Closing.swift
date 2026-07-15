import Foundation

struct Closing: Identifiable {
    var id: String?
    var date: String
    var expected: Double
    var actual: Double
    var nextBase: Double
    var sentToHistorical: Double
    var difference: Double
    var status: String
    var notes: String
}
