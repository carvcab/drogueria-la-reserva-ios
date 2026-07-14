import SwiftUI

struct PurchasesView: View {
    @State private var purchases: [Purchase] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(purchases) { purchase in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(purchase.createdAt?.dateValue() ?? Date(), style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(Helpers.formatCurrency(purchase.total))
                                .font(.headline)
                                .bold()
                        }
                        if let provider = purchase.providerName {
                            Text("Proveedor: \(provider)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("Factura: \(purchase.invoiceNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Compras")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear { loadPurchases() }
    }

    private func loadPurchases() {
        Task {
            if let result = try? await FirebaseService.shared.getPurchases() {
                await MainActor.run { purchases = result }
            }
        }
    }
}

extension FirebaseService {
    func getPurchases() async throws -> [Purchase] {
        let snapshot = try await db.collection("purchases")
            .order(by: "createdAt", descending: true).get()
        return snapshot.documents.compactMap { try? $0.data(as: Purchase.self) }
    }
}
