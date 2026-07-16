import SwiftUI
import FirebaseFirestore

struct OwnConsumptionsView: View {
    @State private var ownConsumptions: [OwnConsumption] = []
    @State private var products: [Product] = []
    @State private var searchText = ""
    @State private var isLoading = true

    @State private var showForm = false
    @State private var editingConsumption: OwnConsumption? = nil

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

                    if isLoading && ownConsumptions.isEmpty && products.isEmpty {
                        Spacer()
                        ProgressView("Conectando con la base de datos...")
                            .foregroundColor(AppColors.textMuted)
                        Spacer()
                    } else if filteredConsumptions.isEmpty {
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingConsumption = item
                                    showForm = true
                                }
                                .listRowBackground(Color.white.opacity(0.85))
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingConsumption = item
                                        showForm = true
                                    } label: {
                                        Label("Editar", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task {
                                            try? await FirebaseService.shared.deleteOwnConsumptionWithReversal(item)
                                        }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
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
                    Button(action: {
                        editingConsumption = nil
                        showForm = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                OwnConsumptionFormView(
                    products: products,
                    existing: editingConsumption,
                    onSave: { showForm = false }
                )
            }
        }
        .task {
            await loadAll()
        }
        .onDisappear {
            ownConsumptionsListener?.remove()
            productsListener?.remove()
        }
    }

    private func loadAll() async {
        isLoading = true
        do {
            if let prods = try? await FirebaseService.shared.getProducts() {
                await MainActor.run { self.products = prods }
            }
            if let cons = try? await FirebaseService.shared.getOwnConsumptions() {
                await MainActor.run { self.ownConsumptions = cons }
            }
        }
        await MainActor.run { isLoading = false }

        // Set up realtime listeners after initial load
        ownConsumptionsListener = FirebaseService.shared.listenOwnConsumptions { list in
            self.ownConsumptions = list
        }
        productsListener = FirebaseService.shared.listenProducts { list in
            self.products = list
        }
    }
}

struct OwnConsumptionFormView: View {
    @Environment(\.dismiss) var dismiss
    let products: [Product]
    let existing: OwnConsumption?
    let onSave: () -> Void

    @State private var searchQuery = ""
    @State private var selectedProduct: Product?
    @State private var qty = 1
    @State private var description = ""
    @State private var showScanner = false
    @State private var localProducts: [Product] = []
    @State private var isLoadingProducts = false

    private var isEditing: Bool { existing != nil }

    private var displayProducts: [Product] {
        localProducts.isEmpty ? products : localProducts
    }

    private var filteredProducts: [Product] {
        if searchQuery.isEmpty { return displayProducts }
        return displayProducts.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.barcode ?? "").localizedCaseInsensitiveContains(searchQuery)
        }
    }

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

                Section("Buscar Medicamento") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textMuted)
                        TextField("Escribir nombre del producto...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .disabled(isLoadingProducts)
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }
                    }
                }

                if isLoadingProducts {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Obteniendo productos...")
                            Spacer()
                        }
                    }
                } else if selectedProduct == nil {
                    Section {
                        if filteredProducts.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    if searchQuery.isEmpty {
                                        Text("No se encontraron productos en la base de datos")
                                            .foregroundColor(AppColors.textMuted)
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                    } else {
                                        Text("Sin resultados para \"\(searchQuery)\"")
                                            .foregroundColor(AppColors.textMuted)
                                            .font(.caption)
                                    }
                                }
                                Spacer()
                            }
                        } else {
                            ForEach(Array(filteredProducts.prefix(20).enumerated()), id: \.element.id) { _, prod in
                                Button(action: {
                                    selectedProduct = prod
                                    searchQuery = prod.name
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(prod.name)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(AppColors.textPrimary)
                                            Text("Stock: \(prod.stock) u | \(prod.category.isEmpty ? "-" : prod.category)")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textMuted)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(AppColors.primary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    } header: {
                        Text(searchQuery.isEmpty ? "Todos los productos (\(displayProducts.count))" : "Resultados: \(filteredProducts.count)")
                    }
                }

                if let prod = selectedProduct {
                    Section("Producto Seleccionado") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(prod.name)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Stock disponible: \(prod.stock) u")
                                    .font(.caption)
                                    .foregroundColor(prod.stock > 0 ? AppColors.primary : AppColors.danger)
                            }
                            Spacer()
                            Button(action: { selectedProduct = nil; searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.textMuted)
                                    .font(.title3)
                            }
                        }
                    }
                }

                if let prod = selectedProduct ?? existing.flatMap({ ex in displayProducts.first(where: { $0.id == ex.productId || $0.name == ex.productName }) }) {
                    Section("Detalles del Autoconsumo") {
                        Stepper("Cantidad: \(qty)", value: $qty, in: 1...max(1, prod.stock + (existing?.qty ?? 0)))
                        TextField("Motivo / Justificación del autoconsumo", text: $description)
                    }

                    Section {
                        Button(action: saveConsumption) {
                            Text(isEditing ? "Actualizar Consumo (Recalcular)" : "Registrar Consumo Propio")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isEditing ? Color.blue : AppColors.primary)
                                .cornerRadius(12)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar / Recalcular Consumo" : "Registrar Consumo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    BarcodeScannerView(isPresented: $showScanner) { code in
                        if let matched = displayProducts.first(where: { $0.barcode == code }) {
                            selectedProduct = matched
                            searchQuery = matched.name
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
        .task {
            if products.isEmpty {
                isLoadingProducts = true
                do {
                    let prods = try await FirebaseService.shared.getProducts()
                    await MainActor.run {
                        localProducts = prods
                        isLoadingProducts = false
                    }
                } catch {
                    await MainActor.run { isLoadingProducts = false }
                }
            }
        }
        .onAppear {
            if let ex = existing {
                let allProducts = products.isEmpty ? localProducts : products
                selectedProduct = allProducts.first(where: { $0.id == ex.productId || $0.name == ex.productName })
                qty = ex.qty
                description = ex.description
            }
        }
    }

    private func saveConsumption() {
        let prod: Product?
        if let sp = selectedProduct {
            prod = sp
        } else if let ex = existing {
            let allProducts = products.isEmpty ? localProducts : products
            prod = allProducts.first(where: { $0.id == ex.productId || $0.name == ex.productName })
        } else {
            prod = nil
        }

        guard let prod = prod else { return }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())

        Task {
            if let ex = existing {
                let allProducts = products.isEmpty ? localProducts : products
                if let oldProd = allProducts.first(where: { $0.id == ex.productId || $0.name == ex.productName }) {
                    var oldP = oldProd
                    oldP.stock = oldProd.stock + ex.qty
                    try? await FirebaseService.shared.saveProduct(oldP)
                }

                var p = prod
                p.stock = max(0, prod.stock - qty)
                try? await FirebaseService.shared.saveProduct(p)

                var updated = ex
                updated.date = dateStr
                updated.productId = prod.id ?? ex.productId
                updated.productName = prod.name
                updated.qty = qty
                updated.description = description
                try? await FirebaseService.shared.saveOwnConsumption(updated)
            } else {
                var p = prod
                p.stock = max(0, prod.stock - qty)
                try? await FirebaseService.shared.saveProduct(p)

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
