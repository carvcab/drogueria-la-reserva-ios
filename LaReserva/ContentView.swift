import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
                .tag(0)

            POSView()
                .tabItem {
                    Label("Vender", systemImage: "cart.fill")
                }
                .tag(1)

            InventoryView()
                .tabItem {
                    Label("Bodega", systemImage: "archivebox.fill")
                }
                .tag(2)

            AccountingView()
                .tabItem {
                    Label("Caja", systemImage: "banknote.fill")
                }
                .tag(3)

            MoreView()
                .tabItem {
                    Label("Más", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .accentColor(AppColors.primary)
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Operaciones") {
                    NavigationLink(destination: PurchasesView()) {
                        Label("Compras / Entrada", systemImage: "shippingbox.fill")
                    }
                    NavigationLink(destination: SalesHistoryView()) {
                        Label("Historial de Ventas", systemImage: "clock.fill")
                    }
                    NavigationLink(destination: ReturnsView()) {
                        Label("Devoluciones", systemImage: "arrow.counterclockwise.circle.fill")
                    }
                    NavigationLink(destination: MovementsView()) {
                        Label("Movimientos de Stock", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill")
                    }
                    NavigationLink(destination: CashWithdrawalsView()) {
                        Label("Retiros de Dinero", systemImage: "banknote.fill")
                    }
                    NavigationLink(destination: OwnConsumptionsView()) {
                        Label("Consumo Propio", systemImage: "person.badge.shield.checkmark.fill")
                    }
                }
                
                Section("Administración") {
                    NavigationLink(destination: CustomersView()) {
                        Label("Clientes (Crédito)", systemImage: "person.2.fill")
                    }
                    NavigationLink(destination: ProvidersView()) {
                        Label("Proveedores", systemImage: "truck.box.fill")
                    }
                    NavigationLink(destination: ReportsView()) {
                        Label("Reportes y Gráficos", systemImage: "chart.bar.fill")
                    }
                }
                
                Section("Configuración") {
                    NavigationLink(destination: SettingsView()) {
                        Label("Ajustes", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("Más Opciones")
            .listStyle(.insetGrouped)
        }
    }
}
