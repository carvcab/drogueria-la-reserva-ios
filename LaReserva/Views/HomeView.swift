import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @State private var productCount = 0
    @State private var lowStockCount = 0
    @State private var todaySales: Double = 0
    @State private var todayProfit: Double = 0
    @State private var inventoryValue: Double = 0
    @State private var recentSales: [Sale] = []
    @State private var lowStockProducts: [Product] = []
    @State private var isOnline = true
    @State private var productsListener: ListenerRegistration?
    @State private var salesListener: ListenerRegistration?
    
    @ObservedObject var firebaseService = FirebaseService.shared

    var body: some View {
        NavigationStack {
            AnimatedBackground(showParticles: true) {
                ScrollView {
                    VStack(spacing: 16) {
                        if let errorMsg = firebaseService.lastError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                Text(errorMsg)
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.85))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }

                        // Header Banner with Logo
                        VStack(spacing: 6) {
                            HStack {
                                Image("Logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 44, height: 44)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(AppConstants.businessName)
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("La Reserva · Gramalote")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                // Online/Offline status badge with pulsing dot
                                HStack(spacing: 6) {
                                    PulseDotView(color: isOnline ? AppColors.primary : AppColors.danger)
                                        .frame(width: 8, height: 8)
                                    Text(isOnline ? "En vivo" : "Offline")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isOnline ? AppColors.primary : AppColors.danger)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background((isOnline ? AppColors.primary : AppColors.danger).opacity(0.12))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        }
                        
                        // Main Stats Panel
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                StatCard(
                                    title: "Ventas Hoy",
                                    value: Helpers.formatCurrency(todaySales),
                                    icon: "dollarsign.circle.fill",
                                    color: AppColors.primary,
                                    backgroundColor: AppColors.getPastelColor(3)
                                )
                                StatCard(
                                    title: "Ganancias Hoy",
                                    value: Helpers.formatCurrency(todayProfit),
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: AppColors.info,
                                    backgroundColor: AppColors.getPastelColor(1)
                                )
                            }
                            
                            HStack(spacing: 12) {
                                StatCard(
                                    title: "Medicamentos",
                                    value: "\(productCount)",
                                    icon: "pill.fill",
                                    color: AppColors.primary,
                                    backgroundColor: AppColors.getPastelColor(6)
                                )
                                StatCard(
                                    title: "Valor Bodega",
                                    value: Helpers.formatCurrency(inventoryValue),
                                    icon: "archivebox.fill",
                                    color: .orange,
                                    backgroundColor: AppColors.getPastelColor(4)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick reports shortcut banner
                        NavigationLink(destination: ReportsView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ver Reportes Completos")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(AppColors.primary)
                                    Text("Ganancias, formas de pago y más vendidos")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppColors.primaryLight.opacity(0.65))
                                    .background(.ultraThinMaterial)
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppColors.primary.opacity(0.18), lineWidth: 1.5)
                            )
                            .padding(.horizontal)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Critical Stock list
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Stock Crítico")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text("\(lowStockCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.danger)
                                    .cornerRadius(6)
                            }
                            .padding(.horizontal)
                            
                            if lowStockProducts.isEmpty {
                                HStack {
                                    Spacer()
                                    Label("Stock Seguro", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(AppColors.primary)
                                    Spacer()
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColors.getPastelColor(3).opacity(0.65))
                                        .background(.ultraThinMaterial)
                                )
                                .cornerRadius(10)
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: 6) {
                                    ForEach(lowStockProducts) { product in
                                        HStack {
                                            Text(product.name)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(AppColors.textPrimary)
                                            Spacer()
                                            Text("\(product.stock) u")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(AppColors.danger)
                                        }
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(AppColors.cardRose.opacity(0.65))
                                                .background(.ultraThinMaterial)
                                        )
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Recent Sales
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Últimas Ventas")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            if recentSales.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "cart")
                                        .font(.largeTitle)
                                        .foregroundColor(AppColors.textMuted)
                                    Text("Sin ventas hoy")
                                        .font(.headline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else {
                                ForEach(recentSales) { sale in
                                    SaleItemRow(sale: sale)
                                }
                            }
                        }
                    }
                }
                .background(Color.clear)
            }
            .navigationTitle("Inicio")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startListeners()
            }
            .onDisappear {
                stopListeners()
            }
        }
    }

    private func startListeners() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: Date())

        productsListener = FirebaseService.shared.listenProducts { list in
            self.productCount = list.count
            self.lowStockProducts = list.filter { $0.isLowStock }.suffix(5)
            self.lowStockCount = list.filter { $0.isLowStock }.count
            self.inventoryValue = list.reduce(0.0) { $0 + ($1.price * Double($1.stock)) }
        }

        salesListener = FirebaseService.shared.listenSales { list in
            let activeSales = list.filter { $0.returned != true }
            self.recentSales = Array(activeSales.prefix(5))
            
            let todayActiveSales = activeSales.filter { $0.date.hasPrefix(todayStr) }
            self.todaySales = todayActiveSales.reduce(0.0) { $0 + $1.total }
            self.todayProfit = todayActiveSales.reduce(0.0) { $0 + $1.profit }
        }
    }

    private func stopListeners() {
        productsListener?.remove()
        salesListener?.remove()
    }
}
