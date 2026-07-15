import SwiftUI

struct ReturnsView: View {
    @State private var returns: [Return] = []
    @State private var sales: [Sale] = []
    @State private var products: [Product] = []
    @State private var customers: [Customer] = []
    @State private var showAddReturn = false
    @State private var searchText = ""

    var filteredReturns: [Return] {
        if searchText.isEmpty { return returns }
        return returns.filter {
            $0.invoiceId.localizedCaseInsensitiveContains(searchText) ||
            $0.id?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search panel
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textMuted)
                    TextField("Buscar devolución por factura o ID…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                // Stat Summary
                HStack(spacing: 12) {
                    StatCard(
                        title: "Total Reembolsos",
                        value: Helpers.formatCurrency(returns.reduce(0.0) { $0 + $1.total }),
                        icon: "arrow.counterclockwise.circle.fill",
                        color: AppColors.danger,
                        backgroundColor: AppColors.cardPink
                    )
                    StatCard(
                        title: "Cantidad",
                        value: "\(returns.count)",
                        icon: "doc.text.fill",
                        color: AppColors.info,
                        backgroundColor: AppColors.getPastelColor(1)
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // List
                if filteredReturns.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textMuted)
                        Text("No hay devoluciones registradas")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredReturns) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Factura: \(item.invoiceId.prefix(8))")
                                        .font(.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text(Helpers.formatCurrency(item.total))
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(AppColors.danger)
                                }
                                
                                Text(item.items.map { "\($0.qty)x \($0.name)" }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text("Retornado")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppColors.danger.opacity(0.1))
                                        .foregroundColor(AppColors.danger)
                                        .cornerRadius(4)
                                    Spacer()
                                    Text(item.date)
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
            .background(AppColors.background)
            .navigationTitle("Devoluciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddReturn = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddReturn) {
                ReturnFormView(sales: sales.filter { $0.returned != true }, products: products, customers: customers, onSave: loadData)
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        Task {
            if let result = try? await FirebaseService.shared.getReturns() {
                await MainActor.run { returns = result }
            }
            if let sls = try? await FirebaseService.shared.getSales() {
                await MainActor.run { sales = sls }
            }
            if let prods = try? await FirebaseService.shared.getProducts() {
                await MainActor.run { products = prods }
            }
            if let custs = try? await FirebaseService.shared.getCustomers() {
                await MainActor.run { customers = custs }
            }
        }
    }
}

struct ReturnFormView: View {
    @Environment(\.dismiss) var dismiss
    let sales: [Sale]
    let products: [Product]
    let customers: [Customer]
    let onSave: () -> Void

    @State private var selectedSale: Sale?
    @State private var itemsToReturn: [SaleItem] = []

    var returnTotal: Double {
        itemsToReturn.reduce(0.0) { $0 + ($1.price * Double($1.qty)) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Seleccione Venta Original") {
                    Picker("Venta", selection: $selectedSale) {
                        Text("Seleccione factura").tag(nil as Sale?)
                        ForEach(sales) { s in
                            Text("Factura: \(s.id?.prefix(8) ?? "Venta") (\(Helpers.formatCurrency(s.total)))").tag(s as Sale?)
                        }
                    }
                }

                if let sale = selectedSale {
                    Section("Medicamentos a Devolver") {
                        ForEach(sale.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .bold()
                                    Text("\(item.qty) u. vendidas")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Button(action: { toggleReturnItem(item) }) {
                                    Image(systemName: isItemReturned(item) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isItemReturned(item) ? AppColors.primary : AppColors.textMuted)
                                        .font(.title2)
                                }
                            }
                        }
                    }

                    if !itemsToReturn.isEmpty {
                        Section("Resumen Devolución") {
                            LabeledContent("Total a Reembolsar", value: Helpers.formatCurrency(returnTotal))
                        }

                        Section {
                            Button(action: processReturn) {
                                Text("Procesar Devolución")
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
            }
            .navigationTitle("Nueva Devolución")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func isItemReturned(_ item: SaleItem) -> Bool {
        itemsToReturn.contains { $0.productId == item.productId }
    }

    private func toggleReturnItem(_ item: SaleItem) {
        if isItemReturned(item) {
            itemsToReturn.removeAll { $0.productId == item.productId }
        } else {
            itemsToReturn.append(item)
        }
    }

    private func processReturn() {
        guard var sale = selectedSale, !itemsToReturn.isEmpty else { return }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())
        
        Task {
            // 1. Return stock of items
            for item in itemsToReturn {
                if let prod = products.first(where: { $0.id == item.productId }) {
                    var p = prod
                    p.stock += item.qty
                    try? await FirebaseService.shared.saveProduct(p)
                }
            }

            // 2. Mark sale as returned
            sale.returned = true
            try? await FirebaseService.shared.saveSale(sale)

            // 3. Revert credit transaction if payment method is "fiado"
            if sale.payment == "fiado", !sale.customerId.isEmpty {
                let transaction = CustomerTransaction(
                    id: Helpers.generateId(),
                    customerId: sale.customerId,
                    date: dateStr,
                    type: "payment",
                    amount: returnTotal,
                    saleId: sale.id,
                    notes: "Devolución venta \(sale.id?.prefix(8) ?? "")",
                    method: "ajuste"
                )
                try? await FirebaseService.shared.saveCustomerTransaction(transaction)

                // Deduct from customer credit balance
                if let customer = customers.first(where: { $0.id == sale.customerId }) {
                    var c = customer
                    c.balance = max(0.0, (customer.balance ?? 0.0) - returnTotal)
                    try? await FirebaseService.shared.saveCustomer(c)
                }
            }

            // 4. Save return log
            let returnLog = Return(
                id: Helpers.generateId(),
                date: dateStr,
                invoiceId: sale.id ?? "",
                items: itemsToReturn,
                total: returnTotal
            )
            try? await FirebaseService.shared.saveReturn(returnLog)

            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
