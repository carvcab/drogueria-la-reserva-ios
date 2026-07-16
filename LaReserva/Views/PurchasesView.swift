import SwiftUI
import FirebaseFirestore

struct PurchasesView: View {
    @State private var purchases: [Purchase] = []
    @State private var providers: [Provider] = []
    @State private var products: [Product] = []
    @State private var showAddPurchase = false
    @State private var searchText = ""
    
    @State private var purchasesListener: ListenerRegistration?
    @State private var providersListener: ListenerRegistration?
    @State private var productsListener: ListenerRegistration?

    var filteredPurchases: [Purchase] {
        if searchText.isEmpty { return purchases }
        return purchases.filter {
            $0.providerName.localizedCaseInsensitiveContains(searchText) ||
            $0.invoiceNo.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search panel
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textMuted)
                    TextField("Buscar compra por proveedor o factura…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                // Stat Cards for purchases
                HStack(spacing: 12) {
                    StatCard(
                        title: "Inversión Total",
                        value: Helpers.formatCurrency(purchases.reduce(0.0) { $0 + $1.total }),
                        icon: "shippingbox.fill",
                        color: .orange,
                        backgroundColor: AppColors.getPastelColor(4)
                    )
                    StatCard(
                        title: "Registros",
                        value: "\(purchases.count)",
                        icon: "list.bullet.rectangle.fill",
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryLight
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // List
                if filteredPurchases.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "shippingbox")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textMuted)
                        Text("No hay compras registradas")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredPurchases) { purchase in
                            NavigationLink(destination: PurchaseDetailView(purchase: purchase)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Factura: \(purchase.invoiceNo)")
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Text(Helpers.formatCurrency(purchase.total))
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.orange)
                                    }
                                    
                                    HStack {
                                        Label(purchase.providerName, systemImage: "truck.box.fill")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text(purchase.date.prefix(10))
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textMuted)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Compras / Entradas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddPurchase = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddPurchase) {
                PurchaseFormView(providers: providers, products: products, onSave: {})
            }
        }
        .onAppear {
            purchasesListener = FirebaseService.shared.listenPurchases { list in
                self.purchases = list
            }
            providersListener = FirebaseService.shared.listenProviders { list in
                self.providers = list
            }
            productsListener = FirebaseService.shared.listenProducts { list in
                self.products = list
            }
        }
        .onDisappear {
            purchasesListener?.remove()
            providersListener?.remove()
            productsListener?.remove()
        }
    }
}

struct PurchaseDetailView: View {
    let purchase: Purchase
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section("Resumen de Compra") {
                LabeledContent("Factura Nº", value: purchase.invoiceNo)
                LabeledContent("Proveedor", value: purchase.providerName)
                LabeledContent("Fecha", value: purchase.date)
                LabeledContent("Total Inversión", value: Helpers.formatCurrency(purchase.total))
            }

            Section("Medicamentos Ingresados") {
                ForEach(purchase.lines) { line in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(line.name)
                                .font(.subheadline)
                                .bold()
                            Text("\(line.qty) u. x \(Helpers.formatCurrency(line.cost))")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Text(Helpers.formatCurrency(line.cost * Double(line.qty)))
                            .font(.subheadline)
                            .bold()
                    }
                }
            }

            Section {
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Label("Anular Compra (Revertir Stock)", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Detalle de Compra")
        .navigationBarTitleDisplayMode(.inline)
        .alert("¿Anular Compra?", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Anular", role: .destructive) {
                Task {
                    try? await FirebaseService.shared.deletePurchaseWithReversal(purchase)
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Esta acción eliminará el registro de compra y restará las unidades ingresadas del stock actual de los productos.")
        }
    }
}

struct PurchaseFormView: View {
    @Environment(\.dismiss) var dismiss
    let providers: [Provider]
    let products: [Product]
    let onSave: () -> Void

    @State private var selectedProvider: Provider?
    @State private var invoiceNo = ""
    @State private var purchaseLines: [PurchaseLineInput] = []
    
    // Add product to purchase sheet
    @State private var showAddLine = false
    @State private var selectedProduct: Product?
    @State private var lineQty = 1
    @State private var lineCost = 0.0
    @State private var linePrice = 0.0
    @State private var showScanner = false
    @State private var showProductPicker = false
    @State private var productSearchQuery = ""

    var purchaseTotal: Double {
        purchaseLines.reduce(0.0) { $0 + ($1.cost * Double($1.qty)) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del Ingreso") {
                    Picker("Proveedor", selection: $selectedProvider) {
                        Text("Seleccione proveedor").tag(nil as Provider?)
                        ForEach(providers) { p in
                            Text(p.name).tag(p as Provider?)
                        }
                    }
                    TextField("Número de Factura", text: $invoiceNo)
                }

                Section("Medicamentos de esta Compra") {
                    if purchaseLines.isEmpty {
                        Text("No se han agregado medicamentos")
                            .font(.caption)
                            .foregroundColor(AppColors.textMuted)
                    } else {
                        ForEach(purchaseLines) { line in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(line.product.name)
                                        .font(.subheadline)
                                        .bold()
                                    Text("\(line.qty) u. x \(Helpers.formatCurrency(line.cost))")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Button(action: { removeLine(line) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(AppColors.danger)
                                }
                            }
                        }
                    }
                    
                    Button(action: { showAddLine = true }) {
                        Label("Agregar Medicamento", systemImage: "plus.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Section("Total Compra") {
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(Helpers.formatCurrency(purchaseTotal))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.orange)
                    }
                }

                Section {
                    Button(action: savePurchase) {
                        Text("Registrar Compra")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSave ? AppColors.primaryGradient : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                            .cornerRadius(12)
                    }
                    .listRowInsets(EdgeInsets())
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Registrar Compra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddLine) {
                addLineSheetView
            }
        }
    }

    private var addLineSheetView: some View {
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
                    Button(action: { showProductPicker = true }) {
                        HStack {
                            if let prod = selectedProduct {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(prod.name)
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Stock: \(prod.stock) u")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textMuted)
                                }
                            } else {
                                Text("Toca para buscar y seleccionar producto...")
                                    .foregroundColor(AppColors.textMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                }

                if let prod = selectedProduct {
                    Section("Detalles del Ingreso") {
                        Stepper("Cantidad: \(lineQty)", value: $lineQty, in: 1...5000)
                        
                        HStack {
                            Text("Costo Unitario Compra")
                            Spacer()
                            TextField("$0", value: $lineCost, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        
                        HStack {
                            Text("Nuevo Precio Venta")
                            Spacer()
                            TextField("$0", value: $linePrice, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                    }
                    
                    Section {
                        Button(action: addLine) {
                            Text("Agregar al Ingreso")
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
            .navigationTitle("Agregar Medicamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showAddLine = false }
                }
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    BarcodeScannerView(isPresented: $showScanner) { code in
                        if let matched = products.first(where: { $0.barcode == code }) {
                            selectedProduct = matched
                            productSearchQuery = matched.name
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
            .sheet(isPresented: $showProductPicker) {
                ProductSearchPicker(
                    products: products,
                    searchQuery: $productSearchQuery,
                    selectedProduct: $selectedProduct,
                    isPresented: $showProductPicker
                )
            }
            .onAppear {
                lineQty = 1
                lineCost = 0.0
                linePrice = 0.0
            }
            .onChange(of: selectedProduct) { newValue in
                if let p = newValue {
                    lineCost = p.cost
                    linePrice = p.price
                }
            }
        }
    }

    private var canSave: Bool {
        selectedProvider != nil && !invoiceNo.isEmpty && !purchaseLines.isEmpty
    }

    private func addLine() {
        guard let prod = selectedProduct else { return }
        let input = PurchaseLineInput(product: prod, qty: lineQty, cost: lineCost, salePrice: linePrice)
        purchaseLines.append(input)
        showAddLine = false
        selectedProduct = nil
    }

    private func removeLine(_ line: PurchaseLineInput) {
        purchaseLines.removeAll { $0.id == line.id }
    }

    private func savePurchase() {
        guard let provider = selectedProvider else { return }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())
        
        let lines = purchaseLines.map { line in
            PurchaseLine(
                productId: line.product.id ?? "",
                name: line.product.name,
                qty: line.qty,
                cost: line.cost,
                salePrice: line.salePrice
            )
        }
        
        let purchase = Purchase(
            id: Helpers.generateId(),
            date: dateStr,
            providerName: provider.name,
            invoiceNo: invoiceNo,
            total: purchaseTotal,
            lines: lines
        )
        
        Task {
            // 1. Save purchase record
            try? await FirebaseService.shared.savePurchase(purchase)
            
            // 2. Increase stock & update prices of products
            for line in purchaseLines {
                var p = line.product
                p.stock += line.qty
                p.cost = line.cost
                p.price = line.salePrice
                try? await FirebaseService.shared.saveProduct(p)
            }
            
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}

struct PurchaseLineInput: Identifiable {
    let id = UUID()
    let product: Product
    var qty: Int
    var cost: Double
    var salePrice: Double
}
