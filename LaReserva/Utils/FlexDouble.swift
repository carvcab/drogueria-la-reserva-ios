import Foundation

@propertyWrapper
struct FlexDouble: Codable, Hashable {
    var wrappedValue: Double

    init(wrappedValue: Double = 0) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        guard let container = try? decoder.singleValueContainer() else {
            wrappedValue = 0; return
        }
        if (try? container.decodeNil()) == true {
            wrappedValue = 0; return
        }
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
