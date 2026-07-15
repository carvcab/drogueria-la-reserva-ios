import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

private func flexDouble(_ value: Any?) -> Double {
    if let d = value as? Double { return d }
    if let i = value as? Int { return Double(i) }
    if let n = value as? NSNumber { return n.doubleValue }
    return 0
}

private func flexInt(_ value: Any?) -> Int {
    if let i = value as? Int { return i }
    if let d = value as? Double { return Int(d) }
    if let n = value as? NSNumber { return n.intValue }
    return 0
}

private func flexString(_ value: Any?) -> String {
    if let s = value as? String { return s }
    if let n = value as? NSNumber { return n.stringValue }
    return ""
}

private func parseStock(_ data: [String: Any]) -> Int {
    if let branch = data["stockByBranch"] as? [String: Any],
       let s1 = branch["S1"] as? [String: Any] {
        return flexInt(s1["totalUnits"])
    }
    return flexInt(data["stock"])
}

// MARK: - Model extensions for manual Firestore parsing

extension Product {
    static func fromFirestore(_ data: [String: Any], id: String) -> Product {
        Product(
            id: id,
            name: flexString(data["name"]),
            category: flexString(data["category"]),
            barcode: data["barcode"] as? String,
            location: data["location"] as? String,
            price: flexDouble(data["price"] as Any? ?? data["priceUnit"] as Any?),
            cost: flexDouble(data["cost"] as Any? ?? data["costUnit"] as Any?),
            providerName: data["providerName"] as? String,
            alertThreshold: flexInt(data["alertThreshold"] as Any? ?? 15),
            stock: parseStock(data)
        )
    }
}

extension Customer {
    static func fromFirestore(_ data: [String: Any], id: String) -> Customer {
        Customer(
            id: id,
            name: flexString(data["name"]),
            cedula: flexString(data["cedula"]),
            phone: flexString(data["phone"]),
            address: flexString(data["address"]),
            allowCredit: data["allowCredit"] as? Bool ?? false,
            creditLimit: flexDouble(data["creditLimit"]),
            balance: flexDouble(data["balance"])
        )
    }
}

extension Provider {
    static func fromFirestore(_ data: [String: Any], id: String) -> Provider {
        Provider(
            id: id,
            name: flexString(data["name"]),
            nit: flexString(data["nit"]),
            contact: flexString(data["contact"]),
            phone: flexString(data["phone"]),
            email: flexString(data["email"])
        )
    }
}

extension Sale {
    static func fromFirestore(_ data: [String: Any], id: String) -> Sale {
        let itemsData = data["items"] as? [[String: Any]] ?? []
        let items: [SaleItem] = itemsData.map { itemData in
            SaleItem(
                productId: flexString(itemData["productId"] as Any? ?? itemData["id"] as Any?),
                name: flexString(itemData["name"]),
                qty: flexInt(itemData["qty"]),
                price: flexDouble(itemData["price"]),
                cost: flexDouble(itemData["cost"] as Any? ?? itemData["profit"] as Any?),
                paidAmount: flexDouble(itemData["paidAmount"])
            )
        }
        return Sale(
            id: id,
            date: flexString(data["date"]),
            customerId: flexString(data["customerId"]),
            customerName: flexString(data["customerName"]),
            payment: flexString(data["payment"] as Any? ?? "efectivo"),
            subtotal: flexDouble(data["subtotal"]),
            total: flexDouble(data["total"]),
            received: flexDouble(data["received"]),
            change: flexDouble(data["change"]),
            items: items,
            returned: data["returned"] as? Bool ?? false
        )
    }
}

extension Purchase {
    static func fromFirestore(_ data: [String: Any], id: String) -> Purchase {
        let linesData = data["lines"] as? [[String: Any]] ?? []
        let lines: [PurchaseLine] = linesData.map { lineData in
            PurchaseLine(
                productId: flexString(lineData["productId"] as Any? ?? lineData["id"] as Any?),
                name: flexString(lineData["name"]),
                qty: flexInt(lineData["qty"]),
                cost: flexDouble(lineData["cost"]),
                salePrice: flexDouble(lineData["salePrice"])
            )
        }
        return Purchase(
            id: id,
            date: flexString(data["date"]),
            providerName: flexString(data["providerName"]),
            invoiceNo: flexString(data["invoiceNo"]),
            total: flexDouble(data["total"]),
            lines: lines
        )
    }
}

extension Withdrawal {
    static func fromFirestore(_ data: [String: Any], id: String) -> Withdrawal {
        Withdrawal(
            id: id,
            date: flexString(data["date"]),
            productId: flexString(data["productId"]),
            productName: flexString(data["pName"] as Any? ?? data["productName"] as Any?),
            qty: flexInt(data["qty"]),
            description: flexString(data["description"] as Any? ?? data["desc"] as Any?),
            destination: flexString(data["destination"])
        )
    }
}

extension OwnConsumption {
    static func fromFirestore(_ data: [String: Any], id: String) -> OwnConsumption {
        OwnConsumption(
            id: id,
            date: flexString(data["date"]),
            productId: flexString(data["productId"]),
            productName: flexString(data["pName"] as Any? ?? data["productName"] as Any?),
            qty: flexInt(data["qty"]),
            description: flexString(data["description"] as Any? ?? data["desc"] as Any?)
        )
    }
}

extension Closing {
    static func fromFirestore(_ data: [String: Any], id: String) -> Closing {
        Closing(
            id: id,
            date: flexString(data["date"]),
            expected: flexDouble(data["expected"]),
            actual: flexDouble(data["actual"]),
            nextBase: flexDouble(data["nextBase"]),
            sentToHistorical: flexDouble(data["sentToHistorical"]),
            difference: flexDouble(data["difference"]),
            status: flexString(data["status"]),
            notes: flexString(data["notes"])
        )
    }
}

extension CashWithdrawal {
    static func fromFirestore(_ data: [String: Any], id: String) -> CashWithdrawal {
        CashWithdrawal(
            id: id,
            date: flexString(data["date"]),
            amount: flexDouble(data["amount"]),
            reason: flexString(data["reason"])
        )
    }
}

extension Return {
    static func fromFirestore(_ data: [String: Any], id: String) -> Return {
        let itemsData = data["items"] as? [[String: Any]] ?? []
        let items: [SaleItem] = itemsData.map { itemData in
            SaleItem(
                productId: flexString(itemData["productId"] as Any? ?? itemData["id"] as Any?),
                name: flexString(itemData["name"]),
                qty: flexInt(itemData["qty"]),
                price: flexDouble(itemData["price"]),
                cost: flexDouble(itemData["cost"] as Any? ?? itemData["profit"] as Any?),
                paidAmount: flexDouble(itemData["paidAmount"])
            )
        }
        return Return(
            id: id,
            date: flexString(data["date"]),
            invoiceId: flexString(data["invoiceId"]),
            items: items,
            total: flexDouble(data["total"])
        )
    }
}

extension CustomerTransaction {
    static func fromFirestore(_ data: [String: Any], id: String) -> CustomerTransaction {
        CustomerTransaction(
            id: id,
            customerId: flexString(data["customerId"]),
            date: flexString(data["date"]),
            type: flexString(data["type"] as Any? ?? "credit"),
            amount: flexDouble(data["amount"]),
            saleId: data["saleId"] as? String,
            notes: flexString(data["notes"]),
            method: flexString(data["method"] as Any? ?? "efectivo")
        )
    }
}

// MARK: - FirebaseService

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    let db = Firestore.firestore()
    let storage = Storage.storage()
    @Published var isReady = false
    @Published var isAuthenticated = false
    @Published var lastError: String?

    private init() { setup() }

    private func setup() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))
        db.settings = settings
        isReady = true
        signInAnonymously()
    }

    private func signInAnonymously() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { [weak self] _, error in
                if let error = error {
                    print("Firebase auth error: \(error.localizedDescription)")
                }
                self?.isAuthenticated = true
            }
        } else {
            isAuthenticated = true
        }
    }

    // MARK: - Products
    func getProducts() async throws -> [Product] {
        let snapshot = try await db.collection("products").order(by: "name").getDocuments()
        return snapshot.documents.map { Product.fromFirestore($0.data(), id: $0.documentID) }
    }

    func listenProducts(completion: @escaping ([Product]) -> Void) -> ListenerRegistration {
        db.collection("products").order(by: "name").addSnapshotListener { snapshot, error in
            if let error = error {
                let msg = "Error Productos: \(error.localizedDescription)"
                print(msg); DispatchQueue.main.async { self.lastError = msg }
            }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { Product.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveProduct(_ product: Product) async throws {
        guard let id = product.id, !id.isEmpty else { return }
        let docRef = db.collection("products").document(id)
        let existing = (try? await docRef.getDocument())?.data()
        var data: [String: Any] = [
            "name": product.name,
            "category": product.category,
            "price": product.price,
            "priceUnit": product.price,
            "cost": product.cost,
            "costUnit": product.cost,
            "alertThreshold": product.alertThreshold,
            "stock": product.stock
        ]
        if let b = product.barcode { data["barcode"] = b }
        if let l = product.location { data["location"] = l }
        if let p = product.providerName { data["providerName"] = p }

        var stockByBranch: [String: Any] = ["S1": ["totalUnits": product.stock]]
        if let existingBranch = existing?["stockByBranch"] as? [String: Any] {
            var merged = existingBranch
            merged["S1"] = ["totalUnits": product.stock]
            stockByBranch = merged
        }
        data["stockByBranch"] = stockByBranch
        try await docRef.setData(data)
    }

    func deleteProduct(_ id: String) async throws {
        try await db.collection("products").document(id).delete()
    }

    // MARK: - Sales
    func getSales() async throws -> [Sale] {
        let snapshot = try await db.collection("sales").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.map { Sale.fromFirestore($0.data(), id: $0.documentID) }
    }

    func listenSales(completion: @escaping ([Sale]) -> Void) -> ListenerRegistration {
        db.collection("sales").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                let msg = "Error Ventas: \(error.localizedDescription)"
                print(msg); DispatchQueue.main.async { self.lastError = msg }
            }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { Sale.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveSale(_ sale: Sale) async throws {
        guard let id = sale.id, !id.isEmpty else { return }
        var data: [String: Any] = [
            "date": sale.date,
            "customerId": sale.customerId,
            "customerName": sale.customerName,
            "payment": sale.payment,
            "subtotal": sale.subtotal,
            "total": sale.total,
            "received": sale.received,
            "change": sale.change,
            "items": sale.items.map { ["productId": $0.productId, "name": $0.name, "qty": $0.qty, "price": $0.price, "cost": $0.cost, "paidAmount": $0.paidAmount] },
            "returned": sale.returned ?? false
        ]
        try await db.collection("sales").document(id).setData(data)
    }

    func deleteSale(_ id: String) async throws {
        try await db.collection("sales").document(id).delete()
    }

    func updateSale(_ oldSale: Sale, with newSale: Sale) async throws {
        for item in oldSale.items {
            try? await revertStock(item.productId, qty: item.qty, add: false)
        }
        for item in newSale.items {
            try? await revertStock(item.productId, qty: item.qty, add: true)
        }
        if oldSale.payment == "fiado", !oldSale.customerId.isEmpty {
            try? await adjustBalance(oldSale.customerId, amount: -oldSale.total)
        }
        if newSale.payment == "fiado", !newSale.customerId.isEmpty {
            try? await adjustBalance(newSale.customerId, amount: newSale.total)
        }
        try await saveSale(newSale)
    }

    func deleteSaleWithReversal(_ sale: Sale) async throws {
        for item in sale.items {
            try? await revertStock(item.productId, qty: item.qty, add: false)
        }
        if sale.payment == "fiado", !sale.customerId.isEmpty {
            try? await adjustBalance(sale.customerId, amount: -sale.total)
        }
        if let id = sale.id { try await deleteSale(id) }
    }

    // MARK: - Customers
    func getCustomers() async throws -> [Customer] {
        let snapshot = try await db.collection("customers").order(by: "name").getDocuments()
        return snapshot.documents.map { Customer.fromFirestore($0.data(), id: $0.documentID) }
    }

    func listenCustomers(completion: @escaping ([Customer]) -> Void) -> ListenerRegistration {
        db.collection("customers").order(by: "name").addSnapshotListener { snapshot, error in
            if let error = error {
                let msg = "Error Clientes: \(error.localizedDescription)"
                print(msg); DispatchQueue.main.async { self.lastError = msg }
            }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { Customer.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveCustomer(_ customer: Customer) async throws {
        guard let id = customer.id, !id.isEmpty else { return }
        try await db.collection("customers").document(id).setData([
            "name": customer.name, "cedula": customer.cedula,
            "phone": customer.phone, "address": customer.address,
            "allowCredit": customer.allowCredit,
            "creditLimit": customer.creditLimit, "balance": customer.balance
        ])
    }

    func deleteCustomer(_ id: String) async throws {
        try await db.collection("customers").document(id).delete()
    }

    // MARK: - Providers
    func getProviders() async throws -> [Provider] {
        let snapshot = try await db.collection("providers").order(by: "name").getDocuments()
        return snapshot.documents.map { Provider.fromFirestore($0.data(), id: $0.documentID) }
    }

    func listenProviders(completion: @escaping ([Provider]) -> Void) -> ListenerRegistration {
        db.collection("providers").order(by: "name").addSnapshotListener { snapshot, error in
            if let error = error {
                let msg = "Error Proveedores: \(error.localizedDescription)"
                print(msg); DispatchQueue.main.async { self.lastError = msg }
            }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { Provider.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveProvider(_ provider: Provider) async throws {
        guard let id = provider.id, !id.isEmpty else { return }
        try await db.collection("providers").document(id).setData([
            "name": provider.name, "nit": provider.nit,
            "contact": provider.contact, "phone": provider.phone, "email": provider.email
        ])
    }

    func deleteProvider(_ id: String) async throws {
        try await db.collection("providers").document(id).delete()
    }

    // MARK: - Purchases
    func listenPurchases(completion: @escaping ([Purchase]) -> Void) -> ListenerRegistration {
        db.collection("purchases").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error { print("Error Compras: \(error.localizedDescription)") }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { Purchase.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func savePurchase(_ purchase: Purchase) async throws {
        guard let id = purchase.id, !id.isEmpty else { return }
        try await db.collection("purchases").document(id).setData([
            "date": purchase.date, "providerName": purchase.providerName,
            "invoiceNo": purchase.invoiceNo, "total": purchase.total,
            "lines": purchase.lines.map { ["productId": $0.productId, "name": $0.name, "qty": $0.qty, "cost": $0.cost, "salePrice": $0.salePrice] }
        ])
    }

    func deletePurchaseWithReversal(_ purchase: Purchase) async throws {
        for line in purchase.lines {
            try? await revertStock(line.productId, qty: line.qty, add: true)
        }
        if let id = purchase.id { try await db.collection("purchases").document(id).delete() }
    }

    // MARK: - Withdrawals
    func getWithdrawals() async throws -> [Withdrawal] {
        let snapshot = try await db.collection("withdrawals").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.map { Withdrawal.fromFirestore($0.data(), id: $0.documentID) }
    }

    func listenWithdrawals(completion: @escaping ([Withdrawal]) -> Void) -> ListenerRegistration {
        db.collection("withdrawals").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                let msg = "Error Retiros: \(error.localizedDescription)"
                print(msg); DispatchQueue.main.async { self.lastError = msg }
            }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { Withdrawal.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveWithdrawal(_ item: Withdrawal) async throws {
        guard let id = item.id, !id.isEmpty else { return }
        try await db.collection("withdrawals").document(id).setData([
            "date": item.date, "productId": item.productId,
            "productName": item.productName, "pName": item.productName,
            "qty": item.qty, "description": item.description,
            "desc": item.description, "destination": item.destination
        ])
    }

    // MARK: - OwnConsumptions
    func getOwnConsumptions() async throws -> [OwnConsumption] {
        let snapshot = try await db.collection("ownConsumptions").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.map { OwnConsumption.fromFirestore($0.data(), id: $0.documentID) }
    }

    func listenOwnConsumptions(completion: @escaping ([OwnConsumption]) -> Void) -> ListenerRegistration {
        db.collection("ownConsumptions").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                let msg = "Error Consumos: \(error.localizedDescription)"
                print(msg); DispatchQueue.main.async { self.lastError = msg }
            }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { OwnConsumption.fromFirestore($0.data(), id: $0.documentID) }
            print("Consumos cargados: \(items.count)")
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveOwnConsumption(_ item: OwnConsumption) async throws {
        guard let id = item.id, !id.isEmpty else { return }
        try await db.collection("ownConsumptions").document(id).setData([
            "date": item.date, "productId": item.productId,
            "productName": item.productName, "pName": item.productName,
            "qty": item.qty, "description": item.description, "desc": item.description
        ])
    }

    func deleteOwnConsumptionWithReversal(_ item: OwnConsumption) async throws {
        if !item.productId.isEmpty { try? await revertStock(item.productId, qty: item.qty, add: false) }
        if let id = item.id { try await db.collection("ownConsumptions").document(id).delete() }
    }

    // MARK: - Cash Register & CashWithdrawals
    func listenCashWithdrawals(completion: @escaping ([CashWithdrawal]) -> Void) -> ListenerRegistration {
        db.collection("cashWithdrawals").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                let msg = "Error Retiros Dinero: \(error.localizedDescription)"
                print(msg); DispatchQueue.main.async { self.lastError = msg }
            }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { CashWithdrawal.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveCashWithdrawal(_ item: CashWithdrawal) async throws {
        guard let id = item.id, !id.isEmpty else { return }
        try await db.collection("cashWithdrawals").document(id).setData([
            "date": item.date, "amount": item.amount, "reason": item.reason
        ])
    }

    func deleteCashWithdrawal(_ id: String) async throws {
        try await db.collection("cashWithdrawals").document(id).delete()
    }

    func getCashRegister(completion: @escaping (CashRegister) -> Void) -> ListenerRegistration {
        db.collection("cashRegister").document("current").addSnapshotListener { snapshot, _ in
            if let data = snapshot?.data() {
                completion(CashRegister(base: flexDouble(data["base"]), currentStatus: flexString(data["currentStatus"] as Any? ?? "Abierta")))
            } else {
                completion(CashRegister(base: 0, currentStatus: "Abierta"))
            }
        }
    }

    func updateCashRegister(_ register: CashRegister) async throws {
        try await db.collection("cashRegister").document("current").setData([
            "base": register.base, "currentStatus": register.currentStatus
        ])
    }

    // MARK: - Closings
    func listenClosings(completion: @escaping ([Closing]) -> Void) -> ListenerRegistration {
        db.collection("closings").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error { print("Error Cierres: \(error.localizedDescription)") }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { Closing.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveClosing(_ item: Closing) async throws {
        guard let id = item.id, !id.isEmpty else { return }
        try await db.collection("closings").document(id).setData([
            "date": item.date, "expected": item.expected, "actual": item.actual,
            "nextBase": item.nextBase, "sentToHistorical": item.sentToHistorical,
            "difference": item.difference, "status": item.status, "notes": item.notes
        ])
    }

    // MARK: - Returns
    func getReturns() async throws -> [Return] {
        let snapshot = try await db.collection("returns").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.map { Return.fromFirestore($0.data(), id: $0.documentID) }
    }

    func listenReturns(completion: @escaping ([Return]) -> Void) -> ListenerRegistration {
        db.collection("returns").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error { print("Error Devoluciones: \(error.localizedDescription)") }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { Return.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveReturn(_ item: Return) async throws {
        guard let id = item.id, !id.isEmpty else { return }
        try await db.collection("returns").document(id).setData([
            "date": item.date, "invoiceId": item.invoiceId, "total": item.total,
            "items": item.items.map { ["productId": $0.productId, "name": $0.name, "qty": $0.qty, "price": $0.price, "cost": $0.cost, "paidAmount": $0.paidAmount] }
        ])
    }

    // MARK: - Customer Transactions
    func listenCustomerTransactions(completion: @escaping ([CustomerTransaction]) -> Void) -> ListenerRegistration {
        db.collection("customerTransactions").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error { print("Error Transacciones: \(error.localizedDescription)") }
            guard let docs = snapshot?.documents else { return }
            let items = docs.map { CustomerTransaction.fromFirestore($0.data(), id: $0.documentID) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveCustomerTransaction(_ tx: CustomerTransaction) async throws {
        guard let id = tx.id, !id.isEmpty else { return }
        try await db.collection("customerTransactions").document(id).setData([
            "customerId": tx.customerId, "date": tx.date, "type": tx.type,
            "amount": tx.amount, "saleId": tx.saleId ?? "", "notes": tx.notes, "method": tx.method
        ])
    }

    // MARK: - Helpers
    private func revertStock(_ productId: String, qty: Int, add: Bool) async throws {
        guard !productId.isEmpty else { return }
        let docRef = db.collection("products").document(productId)
        let existing = (try? await docRef.getDocument())?.data() ?? [:]
        var product = Product.fromFirestore(existing, id: productId)
        product.stock = add ? product.stock + qty : max(0, product.stock - qty)
        try await saveProduct(product)
    }

    private func adjustBalance(_ customerId: String, amount: Double) async throws {
        guard !customerId.isEmpty else { return }
        let docRef = db.collection("customers").document(customerId)
        let existing = (try? await docRef.getDocument())?.data() ?? [:]
        var customer = Customer.fromFirestore(existing, id: customerId)
        customer.balance = max(0, customer.balance + amount)
        try await saveCustomer(customer)
    }
}
