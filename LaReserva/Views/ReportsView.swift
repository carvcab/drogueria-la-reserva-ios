import SwiftUI

struct ReportsView: View {
    @State private var products: [Product] = []
    @State private var sales: [Sale] = []

    var topSellers: [SaleItem] {
        let allItems = sales.flatMap { $0.items }
        let grouped = Dictionary(grouping: allItems) { $0.productName }
        return grouped.map { (name, items) in
            SaleItem(
                id: name,
                productId: items.first?.productId ?? "",
                productName: name,
                quantity: items.reduce(0) { $0 + $1.quantity },
                unitPrice: items.first?.unitPrice ?? 0,
                total: items.reduce(0) { $0 + $1.total }
            )
        }
        .sorted { $0.total > $1.total }
        .prefix(10)
        .map { $0 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Resumen") {
                    LabeledContent("Total Productos", value: "\(products.count)")
                    LabeledContent("Total Ventas", value: Helpers.formatCurrency(sales.reduce(0) { $0 + $1.total }))
                    LabeledContent("Stock Crítico", value: "\(products.filter { $0.isLowStock }.count)")
                }

                Section("Top 10 Más Vendidos") {
                    ForEach(Array(topSellers.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text(item.productName)
                                    .font(.subheadline)
                                Text("\(Int(item.quantity)) vendidos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(Helpers.formatCurrency(item.total))
                                .font(.subheadline)
                                .bold()
                        }
                    }
                }
            }
            .navigationTitle("Reportes")
        }
        .onAppear { loadData() }
    }

    private func loadData() {
        Task {
            if let prods = try? await FirebaseService.shared.getProducts() {
                await MainActor.run { products = prods }
            }
            if let result = try? await FirebaseService.shared.getSales() {
                await MainActor.run { sales = result }
            }
        }
    }
}
