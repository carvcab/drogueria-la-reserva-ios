import Foundation
import FirebaseFirestore
import FirebaseStorage

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    @Published var isReady = false

    private init() {
        setup()
    }

    private func setup() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))
        db.settings = settings
        isReady = true
    }

    // MARK: - Products
    func getProducts() async throws -> [Product] {
        let snapshot = try await db.collection("products").order(by: "name").get()
        return snapshot.documents.compactMap { try? $0.data(as: Product.self) }
    }

    func listenProducts(completion: @escaping ([Product]) -> Void) -> ListenerRegistration {
        db.collection("products").order(by: "name").addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let products = docs.compactMap { try? $0.data(as: Product.self) }
            DispatchQueue.main.async { completion(products) }
        }
    }

    func saveProduct(_ product: Product) async throws {
        if let id = product.id {
            try db.collection("products").document(id).setData(from: product)
        } else {
            try db.collection("products").addDocument(from: product)
        }
    }

    func deleteProduct(_ id: String) async throws {
        try await db.collection("products").document(id).delete()
    }

    // MARK: - Sales
    func getSales() async throws -> [Sale] {
        let snapshot = try await db.collection("sales").order(by: "createdAt", descending: true).get()
        return snapshot.documents.compactMap { try? $0.data(as: Sale.self) }
    }

    func listenSales(completion: @escaping ([Sale]) -> Void) -> ListenerRegistration {
        db.collection("sales").order(by: "createdAt", descending: true).addSnapshotListener { snapshot, _ in
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

    // MARK: - Customers
    func getCustomers() async throws -> [Customer] {
        let snapshot = try await db.collection("customers").order(by: "name").get()
        return snapshot.documents.compactMap { try? $0.data(as: Customer.self) }
    }

    func listenCustomers(completion: @escaping ([Customer]) -> Void) -> ListenerRegistration {
        db.collection("customers").order(by: "name").addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let customers = docs.compactMap { try? $0.data(as: Customer.self) }
            DispatchQueue.main.async { completion(customers) }
        }
    }

    // MARK: - Providers
    func getProviders() async throws -> [Provider] {
        let snapshot = try await db.collection("providers").order(by: "name").get()
        return snapshot.documents.compactMap { try? $0.data(as: Provider.self) }
    }

    func listenProviders(completion: @escaping ([Provider]) -> Void) -> ListenerRegistration {
        db.collection("providers").order(by: "name").addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let providers = docs.compactMap { try? $0.data(as: Provider.self) }
            DispatchQueue.main.async { completion(providers) }
        }
    }

    // MARK: - Purchases
    func listenPurchases(completion: @escaping ([Purchase]) -> Void) -> ListenerRegistration {
        db.collection("purchases").order(by: "createdAt", descending: true).addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let purchases = docs.compactMap { try? $0.data(as: Purchase.self) }
            DispatchQueue.main.async { completion(purchases) }
        }
    }

    // MARK: - Generic
    func deleteDocument(collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
}
