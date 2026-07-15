import Foundation
import FirebaseFirestore

struct SaleItem: Codable, Identifiable, Hashable {
    var id: String { productId }
    var productId: String
    var name: String
    var qty: Int
    @FlexDouble var price: Double
    @FlexDouble var cost: Double
    @FlexDouble var paidAmount: Double

    enum CodingKeys: String, CodingKey {
        case productId
        case id
        case name
        case qty
        case price
        case cost
        case profit
        case paidAmount
    }

    init(productId: String, name: String, qty: Int, price: Double, cost: Double = 0.0, paidAmount: Double = 0.0) {
        self.productId = productId
        self.name = name
        self.qty = qty
        self.price = price
        self.cost = cost
        self.paidAmount = paidAmount
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

        if let p = try? container.decode(Double.self, forKey: .price) {
            self.price = p
        } else if let p = try? container.decode(Int.self, forKey: .price) {
            self.price = Double(p)
        } else {
            self.price = 0.0
        }

        if let c = try? container.decode(Double.self, forKey: .cost) {
            self.cost = c
        } else if let c = try? container.decode(Int.self, forKey: .cost) {
            self.cost = Double(c)
        } else if let c = try? container.decode(Double.self, forKey: .profit) {
            self.cost = c
        } else if let c = try? container.decode(Int.self, forKey: .profit) {
            self.cost = Double(c)
        } else {
            self.cost = 0.0
        }

        if let p = try? container.decode(Double.self, forKey: .paidAmount) {
            self.paidAmount = p
        } else if let p = try? container.decode(Int.self, forKey: .paidAmount) {
            self.paidAmount = Double(p)
        } else {
            self.paidAmount = 0.0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productId, forKey: .productId)
        try container.encode(name, forKey: .name)
        try container.encode(qty, forKey: .qty)
        try container.encode(price, forKey: .price)
        try container.encode(cost, forKey: .cost)
        try container.encode(paidAmount, forKey: .paidAmount)
    }
}

struct Sale: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var date: String
    var customerId: String
    var customerName: String
    var payment: String
    @FlexDouble var subtotal: Double
    @FlexDouble var total: Double
    @FlexDouble var received: Double
    @FlexDouble var change: Double
    var items: [SaleItem]
    var returned: Bool?

    var profit: Double {
        items.reduce(0.0) { sum, item in
            let itemCost = item.cost > 0 ? item.cost : 0
            return sum + ((item.price - itemCost) * Double(item.qty))
        }
    }
}

struct Return: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    var invoiceId: String
    var items: [SaleItem]
    @FlexDouble var total: Double
}
