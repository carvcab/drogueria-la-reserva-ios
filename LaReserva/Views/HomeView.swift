import SwiftUI

struct HomeView: View {
    @State private var productCount = 0
    @State private var lowStockCount = 0
    @State private var todaySales: Double = 0
    @State private var recentSales: [Sale] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 4) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.8))
                        Text("La Reserva")
                            .font(.title)
                            .bold()
                        Text(AppConstants.businessName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(AppConstants.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Productos", value: "\(productCount)", icon: "pill.fill", color: .blue)
                        StatCard(title: "Stock Crítico", value: "\(lowStockCount)", icon: "exclamationmark.triangle.fill", color: .red)
                        StatCard(title: "Ventas Hoy", value: Helpers.formatCurrency(todaySales), icon: "dollarsign.circle.fill", color: .green)
                        StatCard(title: "Clientes", value: "—", icon: "person.2.fill", color: .orange)
                    }
                    .padding(.horizontal)

                    // Recent Sales
                    VStack(alignment: .leading) {
                        Text("Ventas Recientes")
                            .font(.headline)
                            .padding(.horizontal)

                        if recentSales.isEmpty {
                            ContentUnavailableView(
                                "Sin ventas hoy",
                                systemImage: "cart",
                                description: Text("Las ventas aparecerán aquí")
                            )
                        } else {
                            ForEach(recentSales) { sale in
                                SaleItemRow(sale: sale)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Inicio")
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        Task {
            if let products = try? await FirebaseService.shared.getProducts() {
                productCount = products.count
                lowStockCount = products.filter { $0.isLowStock }.count
            }
            if let sales = try? await FirebaseService.shared.getSales() {
                recentSales = Array(sales.prefix(10))
                todaySales = sales
                    .filter { $0.createdAt?.dateValue() ?? Date() > Calendar.current.startOfDay(for: Date()) }
                    .reduce(0) { $0 + $1.total }
            }
        }
    }
}
