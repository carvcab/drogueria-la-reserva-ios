import Foundation
import FirebaseFirestore

struct BranchStock: Codable, Hashable {
    var totalUnits: Double?
    
    init(totalUnits: Double? = nil) {
        self.totalUnits = totalUnits
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            totalUnits = d
        } else if let i = try? container.decode(Int.self) {
            totalUnits = Double(i)
        } else if let s = try? container.decode(String.self), let d = Double(s) {
            totalUnits = d
        } else {
            let keyedContainer = try? decoder.container(keyedBy: CodingKeys.self)
            if let d = try? keyedContainer?.decode(Double.self, forKey: .totalUnits) {
                totalUnits = d
            } else if let i = try? keyedContainer?.decode(Int.self, forKey: .totalUnits) {
                totalUnits = Double(i)
            } else if let s = try? keyedContainer?.decode(String.self, forKey: .totalUnits), let d = Double(s) {
                totalUnits = d
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case totalUnits
    }
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

    var isLowStock: Bool { stock <= alertThreshold }
    var isOutOfStock: Bool { stock <= 0 }

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
        
        self._id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.providerName = try container.decodeIfPresent(String.self, forKey: .providerName)
        
        self.price = (try? container.decode(Double.self, forKey: .price)) ?? 
                     (try? container.decode(Int.self, forKey: .price)).map(Double.init) ?? 0.0
        
        self.cost = (try? container.decode(Double.self, forKey: .cost)) ?? 
                    (try? container.decode(Int.self, forKey: .cost)).map(Double.init) ?? 0.0
        
        self.alertThreshold = try container.decodeIfPresent(Int.self, forKey: .alertThreshold) ?? 15
        
        // Stock parsing from stockByBranch or fallback
        var stockSum = 0
        if let stockByBranchDict = try? container.decodeIfPresent([String: BranchStock].self, forKey: .stockByBranch) {
            for (_, branchStock) in stockByBranchDict {
                if let totalUnits = branchStock.totalUnits {
                    stockSum += Int(totalUnits)
                }
            }
        } else if let stockByBranchDirect = try? container.decodeIfPresent([String: Double].self, forKey: .stockByBranch) {
            for (_, value) in stockByBranchDirect {
                stockSum += Int(value)
            }
        } else if let stockByBranchInt = try? container.decodeIfPresent([String: Int].self, forKey: .stockByBranch) {
            for (_, value) in stockByBranchInt {
                stockSum += value
            }
        }
        
        if stockSum > 0 {
            self.stock = stockSum
        } else {
            self.stock = (try? container.decode(Int.self, forKey: .stock)) ?? 
                         (try? container.decode(Double.self, forKey: .stock)).map(Int.init) ?? 0
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
        
        let branchStock = [
            "S1": BranchStock(totalUnits: Double(stock))
        ]
        try container.encode(branchStock, forKey: .stockByBranch)
    }
}
