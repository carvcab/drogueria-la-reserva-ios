import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    let db = Firestore.firestore()
    let storage = Storage.storage()
    @Published var isReady = false
    @Published var isAuthenticated = false
    @Published var lastError: String?

    private init() {
        setup()
    }

    private func setup() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))
        db.settings = settings
        isReady = true
        signInAnonymously()
    }

    private func signInAnonymously() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { [weak self] result, error in
                if let error = error {
                    print("Firebase auth error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.lastError = "Error de Autenticación: \(error.localizedDescription)"
                    }
                } else {
                    self?.isAuthenticated = true
                    print("Firebase authenticated as: \(result?.user.uid ?? "unknown")")
                }
            }
        } else {
            isAuthenticated = true
        }
    }

    // MARK: - Products
    func getProducts() async throws -> [Product] {
        let snapshot = try await db.collection("products").order(by: "name").getDocuments()
        return snapshot.documents.compactMap { doc in
            guard var p = try? doc.data(as: Product.self) else { return nil }
            p.id = p.id ?? doc.documentID
            return p
        }
    }

    func listenProducts(completion: @escaping ([Product]) -> Void) -> ListenerRegistration {
        db.collection("products").order(by: "name").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Firestore listenProducts error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    FirebaseService.shared.lastError = "Error Firestore (Productos): \(error.localizedDescription)"
                }
            }
            guard let docs = snapshot?.documents else { return }
            let products = docs.compactMap { doc in
                guard var p = try? doc.data(as: Product.self) else { return nil }
                p.id = p.id ?? doc.documentID
                return p
            }
            DispatchQueue.main.async { completion(products) }
        }
    }
    func saveProduct(_ product: Product) async throws {
        if let id = product.id {
            let docRef = db.collection("products").document(id)
            let existingData = (try? await docRef.getDocument())?.data()
            var productDict = (try? Firestore.Encoder().encode(product)) ?? [:]
            productDict.removeValue(forKey: "id")

            if let existingStockByBranch = existingData?["stockByBranch"] as? [String: Any] {
                var mergedStockByBranch = existingStockByBranch
                mergedStockByBranch["S1"] = ["totalUnits": product.stock]
                productDict["stockByBranch"] = mergedStockByBranch
            } else {
                productDict["stockByBranch"] = ["S1": ["totalUnits": product.stock]]
            }

            try await docRef.setData(productDict)
        } else {
            var productDict = (try? Firestore.Encoder().encode(product)) ?? [:]
            productDict.removeValue(forKey: "id")
            productDict["stockByBranch"] = ["S1": ["totalUnits": product.stock]]
            try await db.collection("products").addDocument(data: productDict)
        }
    }

    func deleteProduct(_ id: String) async throws {
        try await db.collection("products").document(id).delete()
    }

    func getSales() async throws -> [Sale] {
        let snapshot = try await db.collection("sales").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Sale.self) }
    }

    func listenSales(completion: @escaping ([Sale]) -> Void) -> ListenerRegistration {
        db.collection("sales").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Firestore listenSales error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    FirebaseService.shared.lastError = "Error Firestore (Ventas): \(error.localizedDescription)"
                }
            }
            guard let docs = snapshot?.documents else { return }
            let sales = docs.compactMap { try? $0.data(as: Sale.self) }
            DispatchQueue.main.async { completion(sales) }
        }
    }

    func saveSale(_ sale: Sale) async throws {
        if let id = sale.id {
            try db.collection("sales").document(id).setData(from: sale)
        } else {
            try db.collection("sales").addDocument(from: sale)
        }
    }

    func deleteSale(_ id: String) async throws {
        try await db.collection("sales").document(id).delete()
    }

    func updateSale(_ oldSale: Sale, with newSale: Sale) async throws {
        // 1. Revert old stock
        for item in oldSale.items {
            let docRef = db.collection("products").document(item.productId)
            if let snap = try? await docRef.getDocument(),
               var product = try? snap.data(as: Product.self) {
                product.stock += item.qty
                try? docRef.setData(from: product)
            }
        }
        // 2. Apply new stock
        for item in newSale.items {
            let docRef = db.collection("products").document(item.productId)
            if let snap = try? await docRef.getDocument(),
               var product = try? snap.data(as: Product.self) {
                product.stock = max(0, product.stock - item.qty)
                try? docRef.setData(from: product)
            }
        }
        // 3. Handle credit balance changes
        let wasCredit = oldSale.payment == "fiado" && !oldSale.customerId.isEmpty
        let isCredit  = newSale.payment == "fiado" && !newSale.customerId.isEmpty

        if wasCredit {
            let oldRef = db.collection("customers").document(oldSale.customerId)
            if let snap = try? await oldRef.getDocument(),
               var cust = try? snap.data(as: Customer.self) {
                cust.balance = (cust.balance ?? 0.0) - oldSale.total
                try? oldRef.setData(from: cust)
            }
        }
        if isCredit {
            let newRef = db.collection("customers").document(newSale.customerId)
            if let snap = try? await newRef.getDocument(),
               var cust = try? snap.data(as: Customer.self) {
                cust.balance = (cust.balance ?? 0.0) + newSale.total
                try? newRef.setData(from: cust)
            }
        }
        if wasCredit, let txId = oldSale.id {
            // Remove old annulment transaction if it exists, or add a new one indicating edit
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateStr = df.string(from: Date())
            let tx = CustomerTransaction(
                id: Helpers.generateId(),
                customerId: isCredit ? newSale.customerId : oldSale.customerId,
                date: dateStr,
                type: "adjustment",
                amount: 0,
                saleId: txId,
                notes: "Venta editada — balance recalculado",
                method: "ajuste"
            )
            try? db.collection("customerTransactions").document(tx.id ?? "").setData(from: tx)
        }
        // 4. Save updated sale
        try await saveSale(newSale)
    }

    func deleteSaleWithReversal(_ sale: Sale) async throws {
        if sale.returned == true {
            throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No se puede eliminar una venta devuelta"])
        }
        
        // 1. Revert product stocks
        for item in sale.items {
            let docId = item.productId
            if !docId.isEmpty {
                let docRef = db.collection("products").document(docId)
                if let snapshot = try? await docRef.getDocument(),
                   var product = try? snapshot.data(as: Product.self) {
                    product.stock += item.qty
                    try? docRef.setData(from: product)
                }
            }
        }
        
        // 2. Revert customer balance if credit sale
        if sale.payment == "fiado" && !sale.customerId.isEmpty {
            let docRef = db.collection("customers").document(sale.customerId)
            if let snapshot = try? await docRef.getDocument(),
               var customer = try? snapshot.data(as: Customer.self) {
                customer.balance = (customer.balance ?? 0.0) - sale.total
                try? docRef.setData(from: customer)
            }
            
            // Add annulment transaction
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateStr = df.string(from: Date())
            let tx = CustomerTransaction(
                id: Helpers.generateId(),
                customerId: sale.customerId,
                date: dateStr,
                type: "payment",
                amount: sale.total,
                saleId: sale.id ?? "",
                notes: "Anulación venta \(sale.id?.prefix(8) ?? "")",
                method: "ajuste"
            )
            try? db.collection("customerTransactions").document(tx.id ?? "").setData(from: tx)
        }
        
        // 3. Delete sale document
        if let saleId = sale.id {
            try await deleteSale(saleId)
        }
    }

    // MARK: - Customers
    func getCustomers() async throws -> [Customer] {
        let snapshot = try await db.collection("customers").order(by: "name").getDocuments()
        return snapshot.documents.compactMap { doc in
            guard var c = try? doc.data(as: Customer.self) else { return nil }
            c.id = c.id ?? doc.documentID
            return c
        }
    }
    func listenCustomers(completion: @escaping ([Customer]) -> Void) -> ListenerRegistration {
        db.collection("customers").order(by: "name").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Firestore listenCustomers error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    FirebaseService.shared.lastError = "Error Firestore (Clientes): \(error.localizedDescription)"
                }
            }
            guard let docs = snapshot?.documents else { return }
            let customers = docs.compactMap { doc in
                guard var c = try? doc.data(as: Customer.self) else { return nil }
                c.id = c.id ?? doc.documentID
                return c
            }
            DispatchQueue.main.async { completion(customers) }
        }
    }

    func saveCustomer(_ customer: Customer) async throws {
        if let id = customer.id {
            try db.collection("customers").document(id).setData(from: customer)
        } else {
            try db.collection("customers").addDocument(from: customer)
        }
    }

    func deleteCustomer(_ id: String) async throws {
        try await db.collection("customers").document(id).delete()
    }

    // MARK: - Customer Transactions
    func getCustomerTransactions() async throws -> [CustomerTransaction] {
        let snapshot = try await db.collection("customerTransactions").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CustomerTransaction.self) }
    }

    func listenCustomerTransactions(completion: @escaping ([CustomerTransaction]) -> Void) -> ListenerRegistration {
        db.collection("customerTransactions").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Firestore listenCustomerTransactions error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    FirebaseService.shared.lastError = "Error Firestore (Transacciones): \(error.localizedDescription)"
                }
            }
            guard let docs = snapshot?.documents else { return }
            let txs = docs.compactMap { try? $0.data(as: CustomerTransaction.self) }
            DispatchQueue.main.async { completion(txs) }
        }
    }

    func saveCustomerTransaction(_ transaction: CustomerTransaction) async throws {
        if let id = transaction.id {
            try db.collection("customerTransactions").document(id).setData(from: transaction)
        } else {
            try db.collection("customerTransactions").addDocument(from: transaction)
        }
    }

    func deleteCustomerTransaction(_ id: String) async throws {
        try await db.collection("customerTransactions").document(id).delete()
    }

    // MARK: - Providers
    func getProviders() async throws -> [Provider] {
        let snapshot = try await db.collection("providers").order(by: "name").getDocuments()
        return snapshot.documents.compactMap { doc in
            guard var p = try? doc.data(as: Provider.self) else { return nil }
            p.id = p.id ?? doc.documentID
            return p
        }
    }

    func listenProviders(completion: @escaping ([Provider]) -> Void) -> ListenerRegistration {
        db.collection("providers").order(by: "name").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Firestore listenProviders error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    FirebaseService.shared.lastError = "Error Firestore (Proveedores): \(error.localizedDescription)"
                }
            }
            guard let docs = snapshot?.documents else { return }
            let providers = docs.compactMap { doc in
                guard var p = try? doc.data(as: Provider.self) else { return nil }
                p.id = p.id ?? doc.documentID
                return p
            }
            DispatchQueue.main.async { completion(providers) }
        }
    }

    func saveProvider(_ provider: Provider) async throws {
        if let id = provider.id {
            try db.collection("providers").document(id).setData(from: provider)
        } else {
            try db.collection("providers").addDocument(from: provider)
        }
    }

    func deleteProvider(_ id: String) async throws {
        try await db.collection("providers").document(id).delete()
    }

    // MARK: - Purchases
    func getPurchases() async throws -> [Purchase] {
        let snapshot = try await db.collection("purchases").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Purchase.self) }
    }

    func listenPurchases(completion: @escaping ([Purchase]) -> Void) -> ListenerRegistration {
        db.collection("purchases").order(by: "date", descending: true).addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let purchases = docs.compactMap { try? $0.data(as: Purchase.self) }
            DispatchQueue.main.async { completion(purchases) }
        }
    }

    func savePurchase(_ purchase: Purchase) async throws {
        if let id = purchase.id {
            try db.collection("purchases").document(id).setData(from: purchase)
        } else {
            try db.collection("purchases").addDocument(from: purchase)
        }
    }

    func deletePurchase(_ id: String) async throws {
        try await db.collection("purchases").document(id).delete()
    }

    func deletePurchaseWithReversal(_ purchase: Purchase) async throws {
        // 1. Revert product stock (subtract purchased stock)
        for line in purchase.lines {
            let docId = line.productId
            if !docId.isEmpty {
                let docRef = db.collection("products").document(docId)
                if let snapshot = try? await docRef.getDocument(),
                   var product = try? snapshot.data(as: Product.self) {
                    product.stock = max(0, product.stock - line.qty)
                    try? docRef.setData(from: product)
                }
            }
        }
        
        // 2. Delete purchase document
        if let id = purchase.id {
            try await deletePurchase(id)
        }
    }

    // MARK: - Withdrawals & Consumptions
    func getWithdrawals() async throws -> [Withdrawal] {
        let snapshot = try await db.collection("withdrawals").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { doc in
            guard var item = try? doc.data(as: Withdrawal.self) else { return nil }
            item.id = doc.documentID
            return item
        }
    }

    func listenWithdrawals(completion: @escaping ([Withdrawal]) -> Void) -> ListenerRegistration {
        db.collection("withdrawals").order(by: "date", descending: true).addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { doc in
                guard var item = try? doc.data(as: Withdrawal.self) else { return nil }
                item.id = doc.documentID
                return item
            }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveWithdrawal(_ item: Withdrawal) async throws {
        if let id = item.id {
            try db.collection("withdrawals").document(id).setData(from: item)
        } else {
            try db.collection("withdrawals").addDocument(from: item)
        }
    }

    func deleteWithdrawal(_ id: String) async throws {
        try await db.collection("withdrawals").document(id).delete()
    }

    func getOwnConsumptions() async throws -> [OwnConsumption] {
        let snapshot = try await db.collection("ownConsumptions").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { doc in
            guard var item = try? doc.data(as: OwnConsumption.self) else { return nil }
            item.id = doc.documentID
            return item
        }
    }
    func listenOwnConsumptions(completion: @escaping ([OwnConsumption]) -> Void) -> ListenerRegistration {
        db.collection("ownConsumptions").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Firestore listenOwnConsumptions error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    FirebaseService.shared.lastError = "Error Firestore (Consumos): \(error.localizedDescription)"
                }
            }
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { doc in
                guard var item = try? doc.data(as: OwnConsumption.self) else { return nil }
                item.id = doc.documentID
                return item
            }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveOwnConsumption(_ item: OwnConsumption) async throws {
        if let id = item.id {
            try db.collection("ownConsumptions").document(id).setData(from: item)
        } else {
            try db.collection("ownConsumptions").addDocument(from: item)
        }
    }

    func deleteOwnConsumption(_ id: String) async throws {
        try await db.collection("ownConsumptions").document(id).delete()
    }

    func deleteOwnConsumptionWithReversal(_ item: OwnConsumption) async throws {
        // 1. Revert product stock (add it back)
        let docId = item.productId
        if !docId.isEmpty {
            let docRef = db.collection("products").document(docId)
            if let snapshot = try? await docRef.getDocument(),
               var product = try? snapshot.data(as: Product.self) {
                product.stock += item.qty
                try? docRef.setData(from: product)
            }
        }
        
        // 2. Delete own consumption document
        if let id = item.id {
            try await deleteOwnConsumption(id)
        }
    }

    // MARK: - Cash Register & Cash Withdrawals
    func getCashRegister(completion: @escaping (CashRegister) -> Void) -> ListenerRegistration {
        db.collection("cashRegister").document("current").addSnapshotListener { snapshot, _ in
            if let data = snapshot?.data(), let register = try? snapshot?.data(as: CashRegister.self) {
                DispatchQueue.main.async { completion(register) }
            } else {
                // Return default if empty
                DispatchQueue.main.async { completion(CashRegister(base: 0.0, currentStatus: "Abierta")) }
            }
        }
    }

    func updateCashRegister(_ register: CashRegister) async throws {
        try db.collection("cashRegister").document("current").setData(from: register)
    }

    func getCashWithdrawals() async throws -> [CashWithdrawal] {
        let snapshot = try await db.collection("cashWithdrawals").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CashWithdrawal.self) }
    }

    func listenCashWithdrawals(completion: @escaping ([CashWithdrawal]) -> Void) -> ListenerRegistration {
        db.collection("cashWithdrawals").order(by: "date", descending: true).addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { try? $0.data(as: CashWithdrawal.self) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveCashWithdrawal(_ item: CashWithdrawal) async throws {
        if let id = item.id {
            try db.collection("cashWithdrawals").document(id).setData(from: item)
        } else {
            try db.collection("cashWithdrawals").addDocument(from: item)
        }
    }

    func deleteCashWithdrawal(_ id: String) async throws {
        try await db.collection("cashWithdrawals").document(id).delete()
    }

    // MARK: - Closings
    func getClosings() async throws -> [Closing] {
        let snapshot = try await db.collection("closings").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Closing.self) }
    }

    func listenClosings(completion: @escaping ([Closing]) -> Void) -> ListenerRegistration {
        db.collection("closings").order(by: "date", descending: true).addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { try? $0.data(as: Closing.self) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveClosing(_ item: Closing) async throws {
        if let id = item.id {
            try db.collection("closings").document(id).setData(from: item)
        } else {
            try db.collection("closings").addDocument(from: item)
        }
    }

    func deleteClosing(_ id: String) async throws {
        try await db.collection("closings").document(id).delete()
    }

    // MARK: - Returns
    func getReturns() async throws -> [Return] {
        let snapshot = try await db.collection("returns").order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Return.self) }
    }

    func listenReturns(completion: @escaping ([Return]) -> Void) -> ListenerRegistration {
        db.collection("returns").order(by: "date", descending: true).addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { try? $0.data(as: Return.self) }
            DispatchQueue.main.async { completion(items) }
        }
    }

    func saveReturn(_ item: Return) async throws {
        if let id = item.id {
            try db.collection("returns").document(id).setData(from: item)
        } else {
            try db.collection("returns").addDocument(from: item)
        }
    }

    func deleteReturn(_ id: String) async throws {
        try await db.collection("returns").document(id).delete()
    }

    // MARK: - Generic
    func deleteDocument(collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
}
