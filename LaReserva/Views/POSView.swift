import SwiftUI
import FirebaseFirestore

struct POSView: View {
    @State private var searchText = ""
    @State private var cartItems: [CartItem] = []
    @State private var selectedPayment: String = "efectivo"
    @State private var selectedCustomer: Customer?
    @State private var receivedAmountText = ""
    @State private var showCheckout = false
    @State private var showScanner = false
    @State private var products: [Product] = []
    @State private var customers: [Customer] = []
    
    @State private var productsListener: ListenerRegistration?
    @State private var customersListener: ListenerRegistration?

    let paymentMethods = [
        ("efectivo", "Efectivo", "banknote"),
        ("tarjeta", "Tarjeta", "creditcard"),
        ("transferencia", "Transferencia", "arrow.up.right.and.arrow.down.left.rectangle"),
        ("fiado", "Fiado / Crédito", "person.badge.minus")
    ]

    var filteredProducts: [Product] {
        if searchText.isEmpty { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.barcode?.localizedCaseInsensitiveContains(searchText) == true)
        }
    }

    var cartTotal: Double {
        cartItems.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }

    var changeAmount: Double {
        let received = Double(receivedAmountText) ?? 0.0
        return max(0.0, received - cartTotal)
    }

    var body: some View {
        NavigationStack {
            AnimatedBackground(showParticles: true) {
                VStack(spacing: 0) {
                    // Search Bar with Scanner
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textMuted)
                        TextField("Buscar por nombre o barras…", text: $searchText)
                            .textFieldStyle(.plain)
                        Button(action: { showScanner = true }) {
                            Image(systemName: "camera.viewfinder")
                                .font(.title3)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground).opacity(0.85))
                    .cornerRadius(10)
                    .padding()

                    // Products Display
                    if filteredProducts.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "pills.fill")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textMuted)
                            Text("No se encontraron productos")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(filteredProducts) { product in
                                    ProductCard(product: product) {
                                        addToCart(product)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                    }

                    // Cart Summary (Floating Panel)
                    if !cartItems.isEmpty {
                        VStack(spacing: 8) {
                            Divider()

                            HStack {
                                Text("\(cartItems.reduce(0) { $0 + $1.quantity }) u")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Text(Helpers.formatCurrency(cartTotal))
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(.horizontal)

                            Button(action: {
                                receivedAmountText = ""
                                selectedCustomer = nil
                                selectedPayment = "efectivo"
                                showCheckout = true
                            }) {
                                Text("Cobrar \(Helpers.formatCurrency(cartTotal))")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppColors.primaryGradient)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        .background(Color(.systemBackground).opacity(0.92))
                    }
                }
            }
            .background(Color.clear)
            .navigationTitle("Punto de Venta")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCheckout) {
                checkoutSheetView
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    BarcodeScannerView(isPresented: $showScanner) { code in
                        if let matched = products.first(where: { $0.barcode == code }) {
                            addToCart(matched)
                        } else {
                            searchText = code
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
        .onAppear {
            productsListener = FirebaseService.shared.listenProducts { list in
                self.products = list
            }
            customersListener = FirebaseService.shared.listenCustomers { list in
                self.customers = list
            }
        }
        .onDisappear {
            productsListener?.remove()
            customersListener?.remove()
        }
    }

    private var checkoutSheetView: some View {
        NavigationStack {
            Form {
                Section("Resumen de Compra") {
                    ForEach(cartItems) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.product.name)
                                    .font(.subheadline)
                                    .bold()
                                Text("\(item.quantity) x \(Helpers.formatCurrency(item.product.price))")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Text(Helpers.formatCurrency(item.product.price * Double(item.quantity)))
                                .font(.subheadline)
                                .bold()
                        }
                    }
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(Helpers.formatCurrency(cartTotal))
                            .font(.title2)
                            .bold()
                            .foregroundColor(AppColors.primary)
                    }
                }

                Section("Método de Pago") {
                    Picker("Método", selection: $selectedPayment) {
                        ForEach(paymentMethods, id: \.0) { method in
                            Label(method.1, systemImage: method.2).tag(method.0)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if selectedPayment == "fiado" {
                    Section("Seleccionar Cliente") {
                        Picker("Cliente", selection: $selectedCustomer) {
                            Text("Seleccione un cliente").tag(nil as Customer?)
                            ForEach(customers) { c in
                                Text("\(c.name) (Límite: \(Helpers.formatCurrency(c.creditLimit)))")
                                    .tag(c as Customer?)
                            }
                        }
                    }
                } else if selectedPayment == "efectivo" {
                    Section("Caja y Cambio") {
                        HStack {
                            Text("Recibido")
                            Spacer()
                            TextField("$0", text: $receivedAmountText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        HStack {
                            Text("Cambio / Vueltas")
                            Spacer()
                            Text(Helpers.formatCurrency(changeAmount))
                                .bold()
                                .foregroundColor(changeAmount > 0 ? AppColors.primary : .primary)
                        }
                    }
                }

                Section {
                    Button(action: completeSale) {
                        Text("Confirmar Venta")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canCompleteSale ? AppColors.primaryGradient : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                            .cornerRadius(12)
                    }
                    .disabled(!canCompleteSale)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Finalizar Pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showCheckout = false }
                }
            }
        }
    }

    private var canCompleteSale: Bool {
        if selectedPayment == "fiado" {
            return selectedCustomer != nil
        }
        return true
    }

    private func addToCart(_ product: Product) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(product: product, quantity: 1))
        }
    }

    private func removeFromCart(_ product: Product) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            if cartItems[index].quantity > 1 {
                cartItems[index].quantity -= 1
            } else {
                cartItems.remove(at: index)
            }
        }
    }

    private func completeSale() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())
        
        let saleId = Helpers.generateId()
        
        let saleItems = cartItems.map { item in
            SaleItem(
                productId: item.product.id ?? "",
                name: item.product.name,
                qty: item.quantity,
                price: item.product.price,
                cost: item.product.cost,
                paidAmount: selectedPayment == "fiado" ? 0.0 : item.product.price * Double(item.quantity)
            )
        }
        
        let receivedVal = Double(receivedAmountText) ?? cartTotal
        
        let sale = Sale(
            id: saleId,
            date: dateStr,
            customerId: selectedCustomer?.id ?? "",
            customerName: selectedCustomer?.name ?? "",
            payment: selectedPayment,
            subtotal: cartTotal,
            total: cartTotal,
            received: selectedPayment == "fiado" ? 0.0 : receivedVal,
            change: selectedPayment == "fiado" ? 0.0 : changeAmount,
            items: saleItems,
            returned: false
        )
        
        Task {
            // 1. Deduct stock for each product
            for item in cartItems {
                var p = item.product
                p.stock = max(0, p.stock - item.quantity)
                try? await FirebaseService.shared.saveProduct(p)
            }
            
            // 2. Save the sale
            try? await FirebaseService.shared.saveSale(sale)
            
            // 3. If credit, save customer transaction
            if selectedPayment == "fiado", let cust = selectedCustomer, let custId = cust.id {
                let transaction = CustomerTransaction(
                    id: Helpers.generateId(),
                    customerId: custId,
                    date: dateStr,
                    type: "credit",
                    amount: cartTotal,
                    saleId: saleId,
                    notes: "Fiado venta \(saleId.prefix(8))",
                    method: "fiado"
                )
                try? await FirebaseService.shared.saveCustomerTransaction(transaction)
                
                // Update customer balance locally/db
                var updatedCust = cust
                updatedCust.balance = (cust.balance ?? 0.0) + cartTotal
                try? await FirebaseService.shared.saveCustomer(updatedCust)
            }
            
            await MainActor.run {
                cartItems.removeAll()
                showCheckout = false
            }
        }
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let product: Product
    var quantity: Int
}
