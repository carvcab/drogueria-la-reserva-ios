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
                    Label("Inventario", systemImage: "archivebox.fill")
                }
                .tag(2)

            SalesHistoryView()
                .tabItem {
                    Label("Historial", systemImage: "clock.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(Color(red: 0.0, green: 0.4, blue: 0.8))
    }
}
