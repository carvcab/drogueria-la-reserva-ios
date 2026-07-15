import Foundation

@propertyWrapper
struct FlexDouble: Codable, Hashable {
    var wrappedValue: Double

    init(wrappedValue: Double = 0) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            wrappedValue = d
        } else if let i = try? container.decode(Int.self) {
            wrappedValue = Double(i)
        } else {
            wrappedValue = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
