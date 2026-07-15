import SwiftUI
import FirebaseFirestore

struct OwnConsumptionsView: View {
    @State private var ownConsumptions: [OwnConsumption] = []
    @State private var products: [Product] = []
    @State private var showAddConsumption = false
    @State private var searchText = ""
    
    @State private var ownConsumptionsListener: ListenerRegistration?
    @State private var productsListener: ListenerRegistration?

    var totalItemsConsumed: Int {
        ownConsumptions.reduce(0) { $0 + $1.qty }
    }

    var filteredConsumptions: [OwnConsumption] {
        if searchText.isEmpty { return ownConsumptions }
        return ownConsumptions.filter {
            $0.productName.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            AnimatedBackground(showParticles: true) {
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textMuted)
                        TextField("Buscar consumo propio…", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(10)
                    .background(Color(.systemBackground).opacity(0.85))
                    .cornerRadius(8)
                    .padding()

                    // Stat Cards
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Unidades Consumidas",
                            value: "\(totalItemsConsumed)",
                            icon: "cart.badge.minus",
                            color: AppColors.info,
                            backgroundColor: AppColors.primaryLight
                        )
                        StatCard(
                            title: "Registros de Uso",
                            value: "\(ownConsumptions.count)",
                            icon: "person.fill.badge.minus",
                            color: .orange,
                            backgroundColor: AppColors.getPastelColor(4)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    // Consumptions List
                    if filteredConsumptions.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "person.fill.badge.minus")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textMuted)
                            Text("No hay consumos registrados")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredConsumptions) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: "person.badge.shield.checkmark.fill")
                                        .foregroundColor(AppColors.info)
                                        .padding(10)
                                        .background(AppColors.info.opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.productName)
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        if !item.description.isEmpty {
                                            Text(item.description)
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }

                                        HStack(spacing: 6) {
                                            Image(systemName: "clock")
                                                .font(.caption2)
                                                .foregroundColor(AppColors.textMuted)
                                            Text(item.date)
                                                .font(.caption2)
                                                .foregroundColor(AppColors.textMuted)
                                        }
                                    }

                                    Spacer()

                                    Text("\(item.qty) u")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(AppColors.info)
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(Color.white.opacity(0.85))
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let item = filteredConsumptions[index]
                                    Task {
                                        try? await FirebaseService.shared.deleteOwnConsumptionWithReversal(item)
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
            }
            .background(Color.clear)
            .navigationTitle("Consumo Propio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddConsumption = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddConsumption) {
                OwnConsumptionFormView(products: products, onSave: {})
            }
        }
        .onAppear {
            ownConsumptionsListener = FirebaseService.shared.listenOwnConsumptions { list in
                self.ownConsumptions = list
            }
            productsListener = FirebaseService.shared.listenProducts { list in
                self.products = list
            }
        }
        .onDisappear {
            ownConsumptionsListener?.remove()
            productsListener?.remove()
        }
    }
}

struct OwnConsumptionFormView: View {
    @Environment(\.dismiss) var dismiss
    let products: [Product]
    let onSave: () -> Void

    @State private var selectedProduct: Product?
    @State private var qty = 1
    @State private var description = ""
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Escanear Código de Barras") {
                    Button(action: { showScanner = true }) {
                        Label("Escanear con Cámara", systemImage: "camera.viewfinder")
                            .foregroundColor(AppColors.primary)
                            .bold()
                    }
                }

                Section("Seleccione Medicamento") {
                    Picker("Producto", selection: $selectedProduct) {
                        Text("Seleccione producto").tag(nil as Product?)
                        ForEach(products) { p in
                            Text("\(p.name) (Stock: \(p.stock) u)").tag(p as Product?)
                        }
                    }
                }

                if let prod = selectedProduct {
                    Section("Detalles del Autoconsumo") {
                        Stepper("Cantidad: \(qty)", value: $qty, in: 1...max(1, prod.stock))
                        TextField("Motivo / Justificación del autoconsumo", text: $description)
                    }

                    Section {
                        Button(action: saveConsumption) {
                            Text("Registrar Consumo Propio")
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
            .navigationTitle("Registrar Consumo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    BarcodeScannerView(isPresented: $showScanner) { code in
                        if let matched = products.first(where: { $0.barcode == code }) {
                            selectedProduct = matched
                        }
                    }
                    .navigationTitle("Escanear Código de Barras")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { showScanner = false }
                        }
                    }
                }
            }
        }
    }

    private func saveConsumption() {
        guard let prod = selectedProduct else { return }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())

        Task {
            // 1. Deduct product stock
            var p = prod
            p.stock = max(0, prod.stock - qty)
            try? await FirebaseService.shared.saveProduct(p)

            // 2. Save own consumption record
            let consumption = OwnConsumption(
                id: Helpers.generateId(),
                date: dateStr,
                productId: prod.id ?? "",
                productName: prod.name,
                qty: qty,
                description: description
            )
            try? await FirebaseService.shared.saveOwnConsumption(consumption)

            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
