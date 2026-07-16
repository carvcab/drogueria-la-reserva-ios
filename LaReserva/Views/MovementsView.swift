import SwiftUI

struct MovementsView: View {
    @State private var withdrawals: [Withdrawal] = []
    @State private var ownConsumptions: [OwnConsumption] = []
    @State private var products: [Product] = []
    @State private var showForm = false
    @State private var editingWithdrawal: Withdrawal? = nil
    @State private var editingConsumption: OwnConsumption? = nil
    @State private var selectedSegment = 0
    @State private var searchText = ""

    private var showAddMovement: Binding<Bool> {
        Binding(
            get: { editingWithdrawal == nil && editingConsumption == nil && showForm },
            set: { newValue in
                if newValue {
                    editingWithdrawal = nil
                    editingConsumption = nil
                    showForm = true
                } else {
                    showForm = false
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textMuted)
                    TextField("Buscar movimiento…", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemBackground).opacity(0.85))
                .cornerRadius(8)
                .padding()

                Picker("Tipo", selection: $selectedSegment) {
                    Text("Retiros de Bodega").tag(0)
                    Text("Autoconsumo").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 12)

                if selectedSegment == 0 {
                    let filtered = withdrawals.filter {
                        searchText.isEmpty ||
                        $0.productName.localizedCaseInsensitiveContains(searchText) ||
                        $0.destination.localizedCaseInsensitiveContains(searchText) ||
                        $0.description.localizedCaseInsensitiveContains(searchText)
                    }
                    if filtered.isEmpty {
                        emptyView(title: "No hay retiros registrados", systemImage: "arrow.down.right.and.arrow.up.left")
                    } else {
                        List {
                            ForEach(filtered) { item in
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingWithdrawal = item
                                    editingConsumption = nil
                                    showForm = true
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingWithdrawal = item
                                        editingConsumption = nil
                                        showForm = true
                                    } label: {
                                        Label("Editar", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await deleteWithdrawal(item) }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                } else {
                    let filtered = ownConsumptions.filter {
                        searchText.isEmpty ||
                        $0.productName.localizedCaseInsensitiveContains(searchText) ||
                        $0.description.localizedCaseInsensitiveContains(searchText)
                    }
                    if filtered.isEmpty {
                        emptyView(title: "No hay consumos propios", systemImage: "person.fill.checkmark")
                    } else {
                        List {
                            ForEach(filtered) { item in
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingConsumption = item
                                    editingWithdrawal = nil
                                    showForm = true
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingConsumption = item
                                        editingWithdrawal = nil
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
                                            loadData()
                                        }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Movimientos de Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        editingWithdrawal = nil
                        editingConsumption = nil
                        showForm = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                MovementFormView(
                    products: products,
                    existingWithdrawal: editingWithdrawal,
                    existingConsumption: editingConsumption,
                    onSave: {
                        editingWithdrawal = nil
                        editingConsumption = nil
                        showForm = false
                        loadData()
                    }
                )
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func deleteWithdrawal(_ item: Withdrawal) async {
        if let p = products.first(where: { $0.id == item.productId }) {
            var updated = p
            updated.stock = p.stock + item.qty
            try? await FirebaseService.shared.saveProduct(updated)
        }
        try? await FirebaseService.shared.deleteWithdrawal(item.id ?? "")
        loadData()
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
    let existingWithdrawal: Withdrawal?
    let existingConsumption: OwnConsumption?
    let onSave: () -> Void

    @State private var searchQuery = ""
    @State private var selectedProduct: Product?
    @State private var type = "retiro"
    @State private var qty = 1
    @State private var description = ""
    @State private var destination = "Vencido"
    @State private var localProducts: [Product] = []
    @State private var isLoadingProducts = false

    private var isEditing: Bool { existingWithdrawal != nil || existingConsumption != nil }

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
                    .disabled(isEditing)
                }

                Section("Buscar Medicamento") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textMuted)
                        TextField("Escribir nombre del producto...", text: $searchQuery)
                            .textFieldStyle(.plain)
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }
                    }
                }

                if selectedProduct == nil {
                    Section {
                        if filteredProducts.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    if searchQuery.isEmpty {
                                        Text("Cargando productos...")
                                            .foregroundColor(AppColors.textMuted)
                                            .font(.caption)
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
                        Text(searchQuery.isEmpty ? "Todos los productos (\(products.count))" : "Resultados: \(filteredProducts.count)")
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

                if let prod = selectedProduct ?? getExistingProduct() {
                    Section("Detalles de Ajuste") {
                        let maxQty = prod.stock + (getExistingQty() ?? 0)
                        Stepper("Cantidad: \(qty)", value: $qty, in: 1...max(1, maxQty))

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
                            Text(isEditing ? "Actualizar Movimiento (Recalcular)" : "Confirmar Ajuste")
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
            .navigationTitle(isEditing ? "Editar / Recalcular Movimiento" : "Registrar Movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
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
            let prods = products.isEmpty ? localProducts : products
            if let w = existingWithdrawal {
                type = "retiro"
                selectedProduct = prods.first(where: { $0.id == w.productId || $0.name == w.productName })
                qty = w.qty
                description = w.description
                destination = w.destination
            } else if let c = existingConsumption {
                type = "consumo"
                selectedProduct = prods.first(where: { $0.id == c.productId || $0.name == c.productName })
                qty = c.qty
                description = c.description
            }
        }
    }

    private func getExistingProduct() -> Product? {
        let prods = products.isEmpty ? localProducts : products
        if let w = existingWithdrawal {
            return prods.first(where: { $0.id == w.productId || $0.name == w.productName })
        }
        if let c = existingConsumption {
            return prods.first(where: { $0.id == c.productId || $0.name == c.productName })
        }
        return nil
    }

    private func getExistingQty() -> Int? {
        existingWithdrawal?.qty ?? existingConsumption?.qty
    }

    private func saveMovement() {
        let prod: Product?
        if let sp = selectedProduct {
            prod = sp
        } else if let w = existingWithdrawal {
            prod = products.first(where: { $0.id == w.productId || $0.name == w.productName })
        } else if let c = existingConsumption {
            prod = products.first(where: { $0.id == c.productId || $0.name == c.productName })
        } else {
            prod = nil
        }

        guard let prod = prod else { return }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())

        Task {
            if let exW = existingWithdrawal {
                // EDIT withdrawal: reverse old stock
                if let oldProd = products.first(where: { $0.id == exW.productId || $0.name == exW.productName }) {
                    var oldP = oldProd
                    oldP.stock = oldProd.stock + exW.qty
                    try? await FirebaseService.shared.saveProduct(oldP)
                }

                var p = prod
                p.stock = max(0, prod.stock - qty)
                try? await FirebaseService.shared.saveProduct(p)

                var updated = exW
                updated.date = dateStr
                updated.productId = prod.id ?? exW.productId
                updated.productName = prod.name
                updated.qty = qty
                updated.description = description
                updated.destination = destination
                try? await FirebaseService.shared.saveWithdrawal(updated)
            } else if let exC = existingConsumption {
                // EDIT consumption: reverse old stock
                if let oldProd = products.first(where: { $0.id == exC.productId || $0.name == exC.productName }) {
                    var oldP = oldProd
                    oldP.stock = oldProd.stock + exC.qty
                    try? await FirebaseService.shared.saveProduct(oldP)
                }

                var p = prod
                p.stock = max(0, prod.stock - qty)
                try? await FirebaseService.shared.saveProduct(p)

                var updated = exC
                updated.date = dateStr
                updated.productId = prod.id ?? exC.productId
                updated.productName = prod.name
                updated.qty = qty
                updated.description = description
                try? await FirebaseService.shared.saveOwnConsumption(updated)
            } else {
                // NEW movement
                var updatedProduct = prod
                updatedProduct.stock = max(0, prod.stock - qty)
                try? await FirebaseService.shared.saveProduct(updatedProduct)

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
            }

            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
