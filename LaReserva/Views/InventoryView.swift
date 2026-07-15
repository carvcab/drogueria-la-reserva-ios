import SwiftUI
import FirebaseFirestore

struct InventoryView: View {
    @State private var products: [Product] = []
    @State private var providers: [Provider] = []
    @State private var searchText = ""
    @State private var filterOption = "Todos"
    @State private var showAddProduct = false
    @State private var productsListener: ListenerRegistration?

    let filterOptions = ["Todos", "Stock Crítico", "Sin Stock"]

    var filteredProducts: [Product] {
        var result = products
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.barcode?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
        switch filterOption {
        case "Stock Crítico":
            result = result.filter { $0.isLowStock }
        case "Sin Stock":
            result = result.filter { $0.isOutOfStock }
        default:
            break
        }
        return result
    }

    var body: some View {
        NavigationStack {
            AnimatedBackground(showParticles: true) {
                VStack(spacing: 0) {
                    // Search & Filter Panel
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textMuted)
                            TextField("Buscar producto o código…", text: $searchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        Picker("Filtro", selection: $filterOption) {
                            ForEach(filterOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.85))

                    // Products List
                    if filteredProducts.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "archivebox")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textMuted)
                            Text("No hay medicamentos registrados")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredProducts) { product in
                                NavigationLink(destination: ProductDetailView(product: product, providers: providers, onSave: {})) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(product.name)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(AppColors.textPrimary)
                                            Spacer()
                                            Text(Helpers.formatCurrency(product.price))
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(AppColors.primary)
                                        }
                                        
                                        HStack {
                                            Label("\(product.stock) u", systemImage: "shippingbox.fill")
                                                .font(.caption)
                                                .bold()
                                                .foregroundColor(product.isLowStock ? AppColors.danger : AppColors.primary)
                                            
                                            if let location = product.location, !location.isEmpty {
                                                Label(location, systemImage: "mappin.and.ellipse")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(AppColors.textMuted)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(product.category)
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 1)
                                                .background(AppColors.primary.opacity(0.1))
                                                .foregroundColor(AppColors.primary)
                                                .cornerRadius(4)
                                        }
                                        
                                        if product.isLowStock {
                                            Label("Stock crítico (\(product.alertThreshold) u)", systemImage: "exclamationmark.triangle.fill")
                                                .font(.system(size: 8))
                                                .foregroundColor(AppColors.danger)
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
            .background(Color.clear)
            .navigationTitle("Inventario / Bodega")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddProduct = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddProduct) {
                ProductFormView(providers: providers, onSave: {})
            }
        }
        .onAppear {
            productsListener = FirebaseService.shared.listenProducts { list in
                self.products = list
            }
            loadProviders()
        }
        .onDisappear {
            productsListener?.remove()
        }
    }

    private func loadProviders() {
        Task {
            if let provs = try? await FirebaseService.shared.getProviders() {
                await MainActor.run { providers = provs }
            }
        }
    }
}

struct ProductDetailView: View {
    @State var product: Product
    let providers: [Provider]
    let onSave: () -> Void
    @State private var isEditing = false
    @Environment(\.dismiss) var dismiss

    var profitMargin: Double {
        guard product.cost > 0 else { return 0 }
        return ((product.price - product.cost) / product.price) * 100
    }

    var body: some View {
        Form {
            Section("Información General") {
                LabeledContent("Nombre", value: product.name)
                LabeledContent("Código de barras", value: product.barcode ?? "Sin código")
                LabeledContent("Ubicación en estante", value: product.location ?? "No asignada")
                LabeledContent("Categoría", value: product.category)
            }

            Section("Inventario") {
                LabeledContent("Stock Actual", value: "\(product.stock) unidades")
                LabeledContent("Stock Mínimo Alerta", value: "\(product.alertThreshold) unidades")
                LabeledContent("Estado", value: product.isOutOfStock ? "Agotado" : product.isLowStock ? "Stock Crítico" : "Seguro")
            }

            Section("Precios y Ganancia") {
                LabeledContent("Costo Unitario", value: Helpers.formatCurrency(product.cost))
                LabeledContent("Precio Venta", value: Helpers.formatCurrency(product.price))
                LabeledContent("Margen de Utilidad", value: String(format: "%.1f%%", profitMargin))
            }

            if let provider = product.providerName {
                Section("Proveedor") {
                    Text(provider)
                }
            }
            
            Section {
                Button(action: { isEditing = true }) {
                    Label("Editar Producto", systemImage: "pencil")
                        .foregroundColor(AppColors.primary)
                }
                
                Button(role: .destructive, action: deleteProduct) {
                    Label("Eliminar Producto", systemImage: "trash")
                }
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            ProductFormView(product: product, providers: providers, onSave: {})
        }
        .onAppear {
            if let id = product.id {
                productListener = FirebaseService.shared.db.collection("products").document(id).addSnapshotListener { snapshot, _ in
                    if let updated = try? snapshot?.data(as: Product.self) {
                        self.product = updated
                    }
                }
            }
        }
        .onDisappear {
            productListener?.remove()
        }
    }
    
    @State private var productListener: ListenerRegistration?
    
    private func deleteProduct() {
        Task {
            if let id = product.id {
                try? await FirebaseService.shared.deleteProduct(id)
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

struct ProductFormView: View {
    @Environment(\.dismiss) var dismiss
    var product: Product? = nil
    let providers: [Provider]
    let onSave: () -> Void

    @State private var name = ""
    @State private var barcode = ""
    @State private var location = ""
    @State private var category = "Analgésicos"
    @State private var price = 0.0
    @State private var cost = 0.0
    @State private var alertThreshold = 15
    @State private var stock = 0
    @State private var selectedProviderName = ""
    @State private var showScanner = false

    let categories = [
        "Analgésicos", "Antibióticos", "Antigripales", "Cardiovasculares",
        "Vitaminas", "Pediatría", "Dermatológicos", "Gastrointestinales",
        "Respiratorios", "Neurológicos", "Oftálmicos", "Otros"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalles del Medicamento") {
                    TextField("Nombre del producto", text: $name)
                    HStack {
                        TextField("Código de barras", text: $barcode)
                        Button(action: { showScanner = true }) {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    TextField("Ubicación (ej: Estante A1)", text: $location)
                    Picker("Categoría", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("Precios y Costo") {
                    HStack {
                        Text("Costo Unitario")
                        Spacer()
                        TextField("Costo", value: $cost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Precio de Venta")
                        Spacer()
                        TextField("Venta", value: $price, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Control de Inventario") {
                    Stepper("Stock Inicial: \(stock)", value: $stock, in: 0...999999)
                    Stepper("Umbral Alerta Mínima: \(alertThreshold)", value: $alertThreshold, in: 1...500)
                }

                Section("Proveedor") {
                    Picker("Proveedor", selection: $selectedProviderName) {
                        Text("Sin proveedor").tag("")
                        ForEach(providers) { p in
                            Text(p.name).tag(p.name)
                        }
                    }
                }
            }
            .navigationTitle(product == nil ? "Agregar Producto" : "Editar Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveProduct() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let p = product {
                    name = p.name
                    barcode = p.barcode ?? ""
                    location = p.location ?? ""
                    category = p.category
                    price = p.price
                    cost = p.cost
                    alertThreshold = p.alertThreshold
                    stock = p.stock
                    selectedProviderName = p.providerName ?? ""
                }
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    BarcodeScannerView(isPresented: $showScanner) { code in
                        barcode = code
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

    private func saveProduct() {
        let p = Product(
            id: product?.id ?? Helpers.generateId(),
            name: name,
            category: category,
            barcode: barcode.isEmpty ? nil : barcode,
            location: location.isEmpty ? nil : location,
            price: price,
            cost: cost,
            providerName: selectedProviderName.isEmpty ? nil : selectedProviderName,
            alertThreshold: alertThreshold,
            stock: stock
        )

        Task {
            try? await FirebaseService.shared.saveProduct(p)
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
