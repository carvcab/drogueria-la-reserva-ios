import SwiftUI

struct ReportsView: View {
    @State private var products: [Product] = []
    @State private var sales: [Sale] = []

    var totalInventoryCost: Double {
        products.reduce(0.0) { $0 + ($1.cost * Double($1.stock)) }
    }

    var totalInventoryValue: Double {
        products.reduce(0.0) { $0 + ($1.price * Double($1.stock)) }
    }

    var totalSales: Double {
        sales.filter { $0.returned != true }.reduce(0.0) { $0 + $1.total }
    }

    var totalProfit: Double {
        sales.filter { $0.returned != true }.reduce(0.0) { $0 + $1.profit }
    }

    var paymentMethodsStats: [(String, Double)] {
        let activeSales = sales.filter { $0.returned != true }
        let grouped = Dictionary(grouping: activeSales) { $0.payment }
        return grouped.map { (method, salesList) in
            (method.capitalized, salesList.reduce(0.0) { $0 + $1.total })
        }.sorted { $0.1 > $1.1 }
    }

    var topSellers: [TopSellerItem] {
        let activeSales = sales.filter { $0.returned != true }
        let allItems = activeSales.flatMap { $0.items }
        let grouped = Dictionary(grouping: allItems) { $0.name }
        return grouped.map { (name, items) in
            TopSellerItem(
                name: name,
                qty: items.reduce(0) { $0 + $1.qty },
                total: items.reduce(0.0) { $0 + ($1.price * Double($1.qty)) }
            )
        }
        .sorted { $0.qty > $1.qty }
        .prefix(10)
        .map { $0 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Resumen del Negocio") {
                    HStack {
                        Text("Medicamentos")
                        Spacer()
                        Text("\(products.count) ítems")
                            .bold()
                    }
                    
                    HStack {
                        Text("Inversión en Bodega")
                        Spacer()
                        Text(Helpers.formatCurrency(totalInventoryCost))
                            .bold()
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("Valor de Venta Bodega")
                        Spacer()
                        Text(Helpers.formatCurrency(totalInventoryValue))
                            .bold()
                            .foregroundColor(AppColors.primary)
                    }
                }

                Section("Ventas y Rentabilidad") {
                    HStack {
                        Text("Ventas Totales")
                        Spacer()
                        Text(Helpers.formatCurrency(totalSales))
                            .bold()
                            .foregroundColor(AppColors.primary)
                    }

                    HStack {
                        Text("Utilidad / Ganancia")
                        Spacer()
                        Text(Helpers.formatCurrency(totalProfit))
                            .bold()
                            .foregroundColor(AppColors.info)
                    }

                    let margin = totalSales > 0 ? (totalProfit / totalSales) * 100 : 0
                    HStack {
                        Text("Margen de Ganancia Promedio")
                        Spacer()
                        Text(String(format: "%.1f%%", margin))
                            .bold()
                    }
                }

                Section("Ventas por Forma de Pago") {
                    if paymentMethodsStats.isEmpty {
                        Text("Sin datos de pago")
                            .font(.caption)
                            .foregroundColor(AppColors.textMuted)
                    } else {
                        ForEach(paymentMethodsStats, id: \.0) { item in
                            HStack {
                                Text(item.0)
                                Spacer()
                                Text(Helpers.formatCurrency(item.1))
                                    .bold()
                            }
                        }
                    }
                }

                Section("Top 10 Medicamentos Más Vendidos") {
                    if topSellers.isEmpty {
                        Text("Sin datos de venta")
                            .font(.caption)
                            .foregroundColor(AppColors.textMuted)
                    } else {
                        ForEach(Array(topSellers.enumerated()), id: \.element.id) { index, item in
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textMuted)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .bold()
                                    Text("\(item.qty) u. vendidas")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text(Helpers.formatCurrency(item.total))
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reportes de Inventario y Ventas")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadData()
        }
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

struct TopSellerItem: Identifiable {
    let id = UUID()
    let name: String
    let qty: Int
    let total: Double
}
