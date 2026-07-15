import Foundation
import FirebaseFirestore

struct Closing: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    var expected: Double
    var actual: Double
    var nextBase: Double
    var sentToHistorical: Double
    var difference: Double
    var status: String
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case expected
        case actual
        case nextBase
        case sentToHistorical
        case difference
        case status
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        
        self.expected = (try? container.decode(Double.self, forKey: .expected)) ?? 
                        (try? container.decode(Int.self, forKey: .expected)).map(Double.init) ?? 0.0
        
        self.actual = (try? container.decode(Double.self, forKey: .actual)) ?? 
                      (try? container.decode(Int.self, forKey: .actual)).map(Double.init) ?? 0.0
        
        self.nextBase = (try? container.decode(Double.self, forKey: .nextBase)) ?? 
                        (try? container.decode(Int.self, forKey: .nextBase)).map(Double.init) ?? 0.0
        
        self.sentToHistorical = (try? container.decode(Double.self, forKey: .sentToHistorical)) ?? 
                                (try? container.decode(Int.self, forKey: .sentToHistorical)).map(Double.init) ?? 0.0
        
        self.difference = (try? container.decode(Double.self, forKey: .difference)) ?? 
                          (try? container.decode(Int.self, forKey: .difference)).map(Double.init) ?? 0.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(expected, forKey: .expected)
        try container.encode(actual, forKey: .actual)
        try container.encode(nextBase, forKey: .nextBase)
        try container.encode(sentToHistorical, forKey: .sentToHistorical)
        try container.encode(difference, forKey: .difference)
        try container.encode(status, forKey: .status)
        try container.encode(notes, forKey: .notes)
    }
}
