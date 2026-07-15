import Foundation
import FirebaseFirestore

struct BranchStock: Codable, Hashable {
    var totalUnits: FlexDouble?
}

struct Product: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var category: String
    var barcode: String?
    var location: String?
    var price: Double
    var cost: Double
    var providerName: String?
    var alertThreshold: Int
    var stock: Int

    var isLowStock: Bool {
        stock <= alertThreshold
    }

    var isOutOfStock: Bool {
        stock <= 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case barcode
        case location
        case price
        case cost
        case providerName
        case alertThreshold
        case stock
        case stockByBranch
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id)?.wrappedValue
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.providerName = try container.decodeIfPresent(String.self, forKey: .providerName)
        
        // Price safety
        if let pVal = try? container.decode(Double.self, forKey: .price) {
            self.price = pVal
        } else if let pVal = try? container.decode(Int.self, forKey: .price) {
            self.price = Double(pVal)
        } else {
            self.price = 0.0
        }
        
        // Cost safety
        if let cVal = try? container.decode(Double.self, forKey: .cost) {
            self.cost = cVal
        } else if let cVal = try? container.decode(Int.self, forKey: .cost) {
            self.cost = Double(cVal)
        } else {
            self.cost = 0.0
        }
        
        self.alertThreshold = try container.decodeIfPresent(Int.self, forKey: .alertThreshold) ?? 15
        
        // Stock parsing: stockByBranch S1 totalUnits or stock field fallback
        var stockSum = 0
        if let stockByBranchDict = try? container.decodeIfPresent([String: BranchStock].self, forKey: .stockByBranch) {
            for (_, branchStock) in stockByBranchDict {
                if let totalUnits = branchStock.totalUnits?.wrappedValue {
                    stockSum += Int(totalUnits)
                }
            }
        } else if let stockByBranchDirect = try? container.decodeIfPresent([String: FlexDouble].self, forKey: .stockByBranch) {
            for (_, value) in stockByBranchDirect {
                stockSum += Int(value.wrappedValue)
            }
        }
        
        if stockSum > 0 {
            self.stock = stockSum
        } else {
            self.stock = try container.decodeIfPresent(Int.self, forKey: .stock) ?? 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(barcode, forKey: .barcode)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encode(price, forKey: .price)
        try container.encode(cost, forKey: .cost)
        try container.encodeIfPresent(providerName, forKey: .providerName)
        try container.encode(alertThreshold, forKey: .alertThreshold)
        try container.encode(stock, forKey: .stock)
        
        // stockByBranch S1 mapping to preserve Android/Desktop schema
        let branchStock = [
            "S1": BranchStock(totalUnits: FlexDouble(wrappedValue: Double(stock)))
        ]
        try container.encode(branchStock, forKey: .stockByBranch)
    }
}
