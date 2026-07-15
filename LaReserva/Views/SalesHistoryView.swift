import SwiftUI
import FirebaseFirestore

struct SalesHistoryView: View {
    @State private var sales: [Sale] = []
    @State private var searchText = ""
    @State private var listener: ListenerRegistration?

    var filteredSales: [Sale] {
        if searchText.isEmpty { return sales }
        return sales.filter {
            $0.customerName.localizedCaseInsensitiveContains(searchText) ||
            $0.items.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        NavigationStack {
            AnimatedBackground(showParticles: true) {
                VStack(spacing: 0) {
                    // Search panel
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textMuted)
                        TextField("Buscar por cliente o medicamento…", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(10)
                    .background(Color(.systemBackground).opacity(0.85))
                    .cornerRadius(8)
                    .padding()

                    // Summary Dashboard
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Total Recaudado",
                            value: Helpers.formatCurrency(sales.reduce(0) { $0 + $1.total }),
                            icon: "dollarsign.circle.fill",
                            color: AppColors.primary,
                            backgroundColor: AppColors.getPastelColor(3)
                        )
                        StatCard(
                            title: "Transacciones",
                            value: "\(sales.count)",
                            icon: "number.circle.fill",
                            color: AppColors.info,
                            backgroundColor: AppColors.getPastelColor(1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    // Sales List
                    if filteredSales.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textMuted)
                            Text("No se encontraron ventas")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredSales) { sale in
                                NavigationLink(destination: SaleDetailView(sale: sale)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(sale.id?.prefix(8) ?? "Venta")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(AppColors.textPrimary)
                                            Spacer()
                                            Text(Helpers.formatCurrency(sale.total))
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(AppColors.primary)
                                        }
                                        
                                        Text(sale.items.map { "\($0.qty)x \($0.name)" }.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                            .lineLimit(1)

                                        HStack {
                                            Text(sale.payment.uppercased())
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 1)
                                                .background(AppColors.primary.opacity(0.12))
                                                .foregroundColor(AppColors.primary)
                                                .cornerRadius(4)
                                            
                                            if !sale.customerName.isEmpty {
                                                Label(sale.customerName, systemImage: "person.fill")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(AppColors.textMuted)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(sale.date)
                                                .font(.system(size: 9))
                                                .foregroundColor(AppColors.textMuted)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                                .listRowBackground(Color.white.opacity(0.75))
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Historial de Ventas")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                listener = FirebaseService.shared.listenSales { list in
                    self.sales = list
                }
            }
            .onDisappear {
                listener?.remove()
            }
        }
    }
}

struct SaleDetailView: View {
    let sale: Sale
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false

    var body: some View {
        Form {
            Section("Detalle de Factura") {
                LabeledContent("ID Venta", value: sale.id ?? "N/A")
                LabeledContent("Fecha", value: sale.date)
                LabeledContent("Forma de Pago", value: sale.payment.capitalized)
                if !sale.customerName.isEmpty {
                    LabeledContent("Cliente", value: sale.customerName)
                }
            }

            Section("Medicamentos Vendidos") {
                ForEach(sale.items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.subheadline)
                                .bold()
                            Text("\(item.qty) u. x \(Helpers.formatCurrency(item.price))")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Text(Helpers.formatCurrency(item.price * Double(item.qty)))
                            .font(.subheadline)
                            .bold()
                    }
                }
            }

            Section("Resumen Económico") {
                LabeledContent("Subtotal", value: Helpers.formatCurrency(sale.subtotal))
                LabeledContent("Total Cobrado", value: Helpers.formatCurrency(sale.total))
                LabeledContent("Ganancia", value: Helpers.formatCurrency(sale.profit))
                if sale.payment == "efectivo" {
                    LabeledContent("Efectivo Recibido", value: Helpers.formatCurrency(sale.received))
                    LabeledContent("Cambio / Vueltas", value: Helpers.formatCurrency(sale.change))
                }
            }

            Section {
                Button(action: { showEditSheet = true }) {
                    Label("Editar Venta", systemImage: "pencil")
                        .foregroundColor(AppColors.primary)
                }
            }

            Section {
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Label("Anular Venta (Revertir Stock/Saldo)", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Detalle de Venta")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            EditSaleView(sale: sale)
        }
        .alert("¿Anular Venta?", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Anular", role: .destructive) {
                Task {
                    try? await FirebaseService.shared.deleteSaleWithReversal(sale)
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Esta acción eliminará la venta de forma permanente, devolverá el stock a los productos vendidos y ajustará la cuenta de crédito del cliente si aplica.")
        }
    }
}
