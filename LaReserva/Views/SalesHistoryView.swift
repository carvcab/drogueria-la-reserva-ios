import SwiftUI

struct SalesHistoryView: View {
    @State private var sales: [Sale] = []
    @State private var searchText = ""

    var filteredSales: [Sale] {
        if searchText.isEmpty { return sales }
        return sales.filter {
            $0.customerName?.localizedCaseInsensitiveContains(searchText) ?? false ||
            $0.items.contains(where: { $0.productName.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar venta…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                // Summary
                HStack {
                    StatCard(title: "Total Ventas", value: Helpers.formatCurrency(sales.reduce(0) { $0 + $1.total }), icon: "dollarsign", color: .green)
                        .frame(maxWidth: .infinity)
                    StatCard(title: "Cantidad", value: "\(sales.count)", icon: "number", color: .blue)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                List {
                    ForEach(filteredSales) { sale in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(sale.createdAt?.dateValue() ?? Date(), style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(Helpers.formatCurrency(sale.total))
                                    .font(.headline)
                                    .bold()
                            }
                            Text("\(sale.items.count) items • \(sale.paymentMethod)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let customer = sale.customerName {
                                Text(customer)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Historial de Ventas")
        }
        .onAppear {
            loadSales()
        }
    }

    private func loadSales() {
        Task {
            if let result = try? await FirebaseService.shared.getSales() {
                await MainActor.run { sales = result }
            }
        }
    }
}
