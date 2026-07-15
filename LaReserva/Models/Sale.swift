import Foundation
import FirebaseFirestore

struct SaleItem: Codable, Identifiable, Hashable {
    var id: String { productId }
    var productId: String
    var name: String
    var qty: Int
    var price: Double
    var cost: Double
    var paidAmount: Double

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
    var subtotal: Double
    var total: Double
    var received: Double
    var change: Double
    var items: [SaleItem]
    var returned: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case customerId
        case customerName
        case payment
        case subtotal
        case total
        case received
        case change
        case items
        case returned
    }

    init(id: String?, date: String, customerId: String, customerName: String, payment: String, subtotal: Double, total: Double, received: Double, change: Double, items: [SaleItem], returned: Bool?) {
        self.id = id
        self.date = date
        self.customerId = customerId
        self.customerName = customerName
        self.payment = payment
        self.subtotal = subtotal
        self.total = total
        self.received = received
        self.change = change
        self.items = items
        self.returned = returned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.customerId = try container.decodeIfPresent(String.self, forKey: .customerId) ?? ""
        self.customerName = try container.decodeIfPresent(String.self, forKey: .customerName) ?? ""
        self.payment = try container.decodeIfPresent(String.self, forKey: .payment) ?? ""
        self.items = try container.decodeIfPresent([SaleItem].self, forKey: .items) ?? []
        self.returned = try container.decodeIfPresent(Bool.self, forKey: .returned)
        
        self.subtotal = (try? container.decode(Double.self, forKey: .subtotal)) ?? 
                        (try? container.decode(Int.self, forKey: .subtotal)).map(Double.init) ?? 0.0
        
        self.total = (try? container.decode(Double.self, forKey: .total)) ?? 
                     (try? container.decode(Int.self, forKey: .total)).map(Double.init) ?? 0.0
        
        self.received = (try? container.decode(Double.self, forKey: .received)) ?? 
                        (try? container.decode(Int.self, forKey: .received)).map(Double.init) ?? 0.0
        
        self.change = (try? container.decode(Double.self, forKey: .change)) ?? 
                      (try? container.decode(Int.self, forKey: .change)).map(Double.init) ?? 0.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(customerId, forKey: .customerId)
        try container.encode(customerName, forKey: .customerName)
        try container.encode(payment, forKey: .payment)
        try container.encode(subtotal, forKey: .subtotal)
        try container.encode(total, forKey: .total)
        try container.encode(received, forKey: .received)
        try container.encode(change, forKey: .change)
        try container.encode(items, forKey: .items)
        try container.encodeIfPresent(returned, forKey: .returned)
    }

    var profit: Double {
        items.reduce(0.0) { sum, item in
            let itemCost = item.cost > 0 ? item.cost : 0.0
            return sum + ((item.price - itemCost) * Double(item.qty))
        }
    }
}

struct Return: Identifiable, Codable {
    @DocumentID var id: String?
    var date: String
    var invoiceId: String
    var items: [SaleItem]
    var total: Double

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case invoiceId
        case items
        case total
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.invoiceId = try container.decodeIfPresent(String.self, forKey: .invoiceId) ?? ""
        self.items = try container.decodeIfPresent([SaleItem].self, forKey: .items) ?? []
        
        self.total = (try? container.decode(Double.self, forKey: .total)) ?? 
                     (try? container.decode(Int.self, forKey: .total)).map(Double.init) ?? 0.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(invoiceId, forKey: .invoiceId)
        try container.encode(items, forKey: .items)
        try container.encode(total, forKey: .total)
    }
}
