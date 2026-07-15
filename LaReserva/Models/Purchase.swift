import Foundation
import FirebaseFirestore

struct PurchaseLine: Codable, Identifiable {
    var id: String { productId }
    var productId: String
    var name: String
    var qty: Int
    var cost: Double
    var salePrice: Double

    enum CodingKeys: String, CodingKey {
        case productId
        case id
        case name
        case qty
        case cost
        case salePrice
    }

    init(productId: String, name: String, qty: Int, cost: Double, salePrice: Double) {
        self.productId = productId
        self.name = name
        self.qty = qty
        self.cost = cost
        self.salePrice = salePrice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let pid = try? container.decode(String.self, forKey: .productId) {
            self.productId = pid
        } else if let pid = try? container.decode(String.self, forKey: .id) {
            self.productId = pid
        } else {
            self.productId = ""
        }

        self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
        self.qty = (try? container.decode(Int.self, forKey: .qty)) ?? 0

        if let c = try? container.decode(Double.self, forKey: .cost) {
            self.cost = c
        } else if let c = try? container.decode(Int.self, forKey: .cost) {
            self.cost = Double(c)
        } else {
            self.cost = 0.0
        }

        if let p = try? container.decode(Double.self, forKey: .salePrice) {
            self.salePrice = p
        } else if let p = try? container.decode(Int.self, forKey: .salePrice) {
            self.salePrice = Double(p)
        } else {
            self.salePrice = 0.0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productId, forKey: .productId)
        try container.encode(name, forKey: .name)
        try container.encode(qty, forKey: .qty)
        try container.encode(cost, forKey: .cost)
        try container.encode(salePrice, forKey: .salePrice)
    }
}

struct Purchase: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    var providerName: String
    var invoiceNo: String
    var total: Double
    var lines: [PurchaseLine]

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case providerName
        case invoiceNo
        case total
        case lines
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.providerName = try container.decodeIfPresent(String.self, forKey: .providerName) ?? ""
        self.invoiceNo = try container.decodeIfPresent(String.self, forKey: .invoiceNo) ?? ""
        self.lines = try container.decodeIfPresent([PurchaseLine].self, forKey: .lines) ?? []
        
        self.total = (try? container.decode(Double.self, forKey: .total)) ?? 
                     (try? container.decode(Int.self, forKey: .total)).map(Double.init) ?? 0.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(providerName, forKey: .providerName)
        try container.encode(invoiceNo, forKey: .invoiceNo)
        try container.encode(total, forKey: .total)
        try container.encode(lines, forKey: .lines)
    }
}
