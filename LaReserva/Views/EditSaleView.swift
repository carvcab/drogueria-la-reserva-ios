import SwiftUI
import FirebaseFirestore

struct EditSaleView: View {
    let originalSale: Sale
    @Environment(\.dismiss) var dismiss

    @State private var items: [SaleItem]
    @State private var payment: String
    @State private var selectedCustomer: Customer?
    @State private var receivedText: String

    @State private var products: [Product] = []
    @State private var customers: [Customer] = []
    @State private var searchText = ""
    @State private var showProductPicker = false
    @State private var productsListener: ListenerRegistration?
    @State private var customersListener: ListenerRegistration?
    @State private var saving = false

    init(sale: Sale) {
        self.originalSale = sale
        _items = State(initialValue: sale.items)
        _payment = State(initialValue: sale.payment)
        _receivedText = State(initialValue: sale.received > 0 ? String(format: "%.0f", sale.received) : "")
        _selectedCustomer = State(initialValue: nil)
    }

    var subtotal: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.qty)) }
    }

    var total: Double {
        subtotal
    }

    var changeAmount: Double {
        let received = Double(receivedText) ?? 0.0
        return max(0.0, received - total)
    }

    var filteredProducts: [Product] {
        if searchText.isEmpty { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.barcode?.localizedCaseInsensitiveContains(searchText) == true)
        }
    }

    let paymentMethods = [
        ("efectivo", "Efectivo", "banknote"),
        ("tarjeta", "Tarjeta", "creditcard"),
        ("transferencia", "Transferencia", "arrow.up.right.and.arrow.down.left.rectangle"),
        ("fiado", "Fiado / Crédito", "person.badge.minus")
    ]

    var body: some View {
        NavigationStack {
            AnimatedBackground(showParticles: true) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Items section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Productos")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Button(action: { showProductPicker = true }) {
                                    Label("Agregar", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.primary)
                                }
                            }

                            if items.isEmpty {
                                Text("No hay productos en esta venta")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textMuted)
                                    .padding(.vertical, 8)
                            }

                            ForEach($items) { $item in
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(AppColors.textPrimary)
                                        HStack(spacing: 4) {
                                            Text("Cant:")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textMuted)
                                            TextField("", value: $item.qty, format: .number)
                                                .keyboardType(.numberPad)
                                                .frame(width: 50)
                                                .textFieldStyle(.roundedBorder)
                                                .font(.caption)
                                                .onChange(of: item.qty) { newVal in
                                                    if newVal < 1 { item.qty = 1 }
                                                }

                                            Text("Precio:")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textMuted)
                                            TextField("", value: $item.price, format: .number)
                                                .keyboardType(.decimalPad)
                                                .frame(width: 70)
                                                .textFieldStyle(.roundedBorder)
                                                .font(.caption)
                                        }
                                    }
                                    Spacer()
                                    Text(Helpers.formatCurrency(item.price * Double(item.qty)))
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(AppColors.primary)

                                    Button(action: { items.removeAll { $0.productId == item.productId } }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                                .padding(10)
                                .background(Color(.systemBackground).opacity(0.9))
                                .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        .background(AppColors.getPastelColor(4).opacity(0.3))
                        .cornerRadius(12)

                        // Payment method
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Forma de Pago")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            HStack(spacing: 8) {
                                ForEach(paymentMethods, id: \.0) { (key, label, icon) in
                                    Button(action: { payment = key }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: icon)
                                                .font(.headline)
                                            Text(label)
                                                .font(.system(size: 9))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(payment == key ? AppColors.primary : Color(.systemBackground).opacity(0.85))
                                        .foregroundColor(payment == key ? .white : AppColors.textSecondary)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(AppColors.getPastelColor(1).opacity(0.3))
                        .cornerRadius(12)

                        // Customer for credit
                        if payment == "fiado" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cliente")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                if let customer = selectedCustomer {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(customer.name).bold()
                                            if !customer.cedula.isEmpty {
                                                Text("Cédula: \(customer.cedula)")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.textMuted)
                                            }
                                        }
                                        Spacer()
                                        Button("Cambiar") { selectedCustomer = nil }
                                            .font(.caption)
                                            .foregroundColor(AppColors.primary)
                                    }
                                    .padding(10)
                                    .background(Color(.systemBackground).opacity(0.9))
                                    .cornerRadius(8)
                                }
                                Picker("Seleccionar cliente", selection: $selectedCustomer) {
                                    Text("Ninguno").tag(nil as Customer?)
                                    ForEach(customers) { customer in
                                        Text(customer.name).tag(customer as Customer?)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(12)
                            .background(AppColors.getPastelColor(2).opacity(0.3))
                            .cornerRadius(12)
                        }

                        // Cash received (efectivo)
                        if payment == "efectivo" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Efectivo Recibido")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                TextField("Monto recibido", text: $receivedText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding(12)
                            .background(AppColors.getPastelColor(3).opacity(0.3))
                            .cornerRadius(12)
                        }

                        // Totals summary
                        VStack(spacing: 8) {
                            HStack { Text("Subtotal").foregroundColor(AppColors.textSecondary); Spacer(); Text(Helpers.formatCurrency(subtotal)).bold() }
                            HStack { Text("Total").font(.headline).foregroundColor(AppColors.textPrimary); Spacer(); Text(Helpers.formatCurrency(total)).font(.headline).bold().foregroundColor(AppColors.primary) }
                            if payment == "efectivo" {
                                if changeAmount > 0 {
                                    HStack { Text("Cambio").foregroundColor(.green); Spacer(); Text(Helpers.formatCurrency(changeAmount)).bold().foregroundColor(.green) }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(12)

                        // Save button
                        Button(action: saveChanges) {
                            HStack {
                                if saving {
                                    ProgressView().tint(.white)
                                }
                                Text(saving ? "Guardando..." : "Guardar Cambios")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(items.isEmpty ? Color.gray : AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(items.isEmpty || saving)
                    }
                    .padding()
                }
            }
            .navigationTitle("Editar Venta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showProductPicker) {
                ProductPickerView(products: filteredProducts, searchText: $searchText) { product in
                    if let idx = items.firstIndex(where: { $0.productId == product.id }) {
                        items[idx].qty += 1
                    } else {
                        let newItem = SaleItem(
                            productId: product.id ?? "",
                            name: product.name,
                            qty: 1,
                            price: product.price,
                            cost: product.cost,
                            paidAmount: 0
                        )
                        items.append(newItem)
                    }
                    showProductPicker = false
                }
            }
            .onAppear {
                restoreCustomer()
                productsListener = FirebaseService.shared.listenProducts { list in
                    self.products = list
                }
                customersListener = FirebaseService.shared.listenCustomers { list in
                    self.customers = list
                    if selectedCustomer == nil, let cust = list.first(where: { $0.id == originalSale.customerId }) {
                        selectedCustomer = cust
                    }
                }
            }
            .onDisappear {
                productsListener?.remove()
                customersListener?.remove()
            }
        }
    }

    private func restoreCustomer() {
        if !originalSale.customerId.isEmpty {
            selectedCustomer = Customer(id: originalSale.customerId, name: originalSale.customerName, cedula: "", phone: "", address: "", allowCredit: true, creditLimit: 0, balance: nil)
        }
    }

    private func saveChanges() {
        saving = true
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let newSale = Sale(
            id: originalSale.id,
            date: originalSale.date, // Keep original date
            customerId: payment == "fiado" ? (selectedCustomer?.id ?? "") : "",
            customerName: payment == "fiado" ? (selectedCustomer?.name ?? "") : "",
            payment: payment,
            subtotal: subtotal,
            total: total,
            received: payment == "efectivo" ? (Double(receivedText) ?? 0.0) : 0.0,
            change: payment == "efectivo" ? changeAmount : 0.0,
            items: items,
            returned: originalSale.returned
        )

        Task {
            do {
                try await FirebaseService.shared.updateSale(originalSale, with: newSale)
                await MainActor.run { dismiss() }
            } catch {
                print("Error updating sale: \(error)")
                await MainActor.run { saving = false }
            }
        }
    }
}

struct ProductPickerView: View {
    let products: [Product]
    @Binding var searchText: String
    let onSelect: (Product) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if products.isEmpty {
                    Text("No se encontraron productos")
                        .foregroundColor(AppColors.textMuted)
                }
                ForEach(products) { product in
                    Button(action: { onSelect(product) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.name).bold()
                                    .foregroundColor(AppColors.textPrimary)
                                Text(Helpers.formatCurrency(product.price))
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Text("Stock: \(product.stock)")
                                .font(.caption)
                                .foregroundColor(product.isLowStock ? .red : AppColors.textMuted)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Buscar producto")
            .navigationTitle("Agregar Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
