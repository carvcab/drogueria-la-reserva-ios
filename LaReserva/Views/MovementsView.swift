import SwiftUI

struct MovementsView: View {
    @State private var withdrawals: [Withdrawal] = []
    @State private var ownConsumptions: [OwnConsumption] = []
    @State private var products: [Product] = []
    @State private var showAddMovement = false
    @State private var selectedSegment = 0 // 0: Retiros, 1: Autoconsumo

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tipo", selection: $selectedSegment) {
                    Text("Retiros de Bodega").tag(0)
                    Text("Autoconsumo").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // List
                if selectedSegment == 0 {
                    if withdrawals.isEmpty {
                        emptyView(title: "No hay retiros registrados", systemImage: "arrow.down.right.and.arrow.up.left")
                    } else {
                        List {
                            ForEach(withdrawals) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.productName)
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Text("\(item.qty) u")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(AppColors.danger)
                                    }
                                    
                                    HStack {
                                        Label(item.destination.uppercased(), systemImage: "tag.fill")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppColors.danger.opacity(0.1))
                                            .foregroundColor(AppColors.danger)
                                            .cornerRadius(4)
                                        
                                        if !item.description.isEmpty {
                                            Text(item.description)
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(item.date.prefix(16))
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textMuted)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    if ownConsumptions.isEmpty {
                        emptyView(title: "No hay consumos propios", systemImage: "person.fill.checkmark")
                    } else {
                        List {
                            ForEach(ownConsumptions) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.productName)
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Text("\(item.qty) u")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(AppColors.info)
                                    }
                                    
                                    HStack {
                                        if !item.description.isEmpty {
                                            Text(item.description)
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(item.date.prefix(16))
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textMuted)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Movimientos de Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddMovement = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddMovement) {
                MovementFormView(products: products, onSave: loadData)
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func emptyView(title: String, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textMuted)
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
    }

    private func loadData() {
        Task {
            if let withs = try? await FirebaseService.shared.getWithdrawals() {
                await MainActor.run { withdrawals = withs }
            }
            if let cons = try? await FirebaseService.shared.getOwnConsumptions() {
                await MainActor.run { ownConsumptions = cons }
            }
            if let prods = try? await FirebaseService.shared.getProducts() {
                await MainActor.run { products = prods }
            }
        }
    }
}

struct MovementFormView: View {
    @Environment(\.dismiss) var dismiss
    let products: [Product]
    let onSave: () -> Void

    @State private var selectedProduct: Product?
    @State private var type = "retiro" // "retiro" or "consumo"
    @State private var qty = 1
    @State private var description = ""
    @State private var destination = "Vencido" // Only for "retiro"

    let destinations = ["Vencido", "Dañado", "Devolución Proveedor", "Ajuste de Inventario", "Otro"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo de Movimiento") {
                    Picker("Tipo", selection: $type) {
                        Text("Retiro de Stock / Merma").tag("retiro")
                        Text("Consumo Propio").tag("consumo")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Seleccione Producto") {
                    Picker("Producto", selection: $selectedProduct) {
                        Text("Seleccione producto").tag(nil as Product?)
                        ForEach(products) { p in
                            Text("\(p.name) (Stock: \(p.stock) u)").tag(p as Product?)
                        }
                    }
                }

                if let prod = selectedProduct {
                    Section("Detalles de Ajuste") {
                        Stepper("Cantidad a Retirar: \(qty)", value: $qty, in: 1...prod.stock)
                        
                        if type == "retiro" {
                            Picker("Motivo de Retiro", selection: $destination) {
                                ForEach(destinations, id: \.self) { d in
                                    Text(d).tag(d)
                                }
                            }
                        }
                        
                        TextField("Descripción o justificación", text: $description)
                    }

                    Section {
                        Button(action: saveMovement) {
                            Text("Confirmar Ajuste")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primaryGradient)
                                .cornerRadius(12)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle("Registrar Movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func saveMovement() {
        guard let prod = selectedProduct else { return }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())
        
        Task {
            // 1. Deduct stock from product
            var updatedProduct = prod
            updatedProduct.stock = max(0, prod.stock - qty)
            try? await FirebaseService.shared.saveProduct(updatedProduct)
            
            // 2. Save movement record
            if type == "retiro" {
                let withdrawal = Withdrawal(
                    id: Helpers.generateId(),
                    date: dateStr,
                    productId: prod.id ?? "",
                    productName: prod.name,
                    qty: qty,
                    description: description,
                    destination: destination
                )
                try? await FirebaseService.shared.saveWithdrawal(withdrawal)
            } else {
                let consumption = OwnConsumption(
                    id: Helpers.generateId(),
                    date: dateStr,
                    productId: prod.id ?? "",
                    productName: prod.name,
                    qty: qty,
                    description: description
                )
                try? await FirebaseService.shared.saveOwnConsumption(consumption)
            }
            
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
