import SwiftUI

struct POSView: View {
    @State private var searchText = ""
    @State private var cartItems: [CartItem] = []
    @State private var selectedPayment: String = "Efectivo"
    @State private var showCheckout = false
    @State private var products: [Product] = []

    let paymentMethods = ["Efectivo", "Tarjeta", "Transferencia", "Crédito"]

    var filteredProducts: [Product] {
        if searchText.isEmpty { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.barcode.localizedCaseInsensitiveContains(searchText)
        }
    }

    var cartTotal: Double {
        cartItems.reduce(0) { $0 + ($1.product.salePrice * $1.quantity) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar producto o código…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Products Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(filteredProducts) { product in
                            ProductCard(product: product) {
                                addToCart(product)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Cart Summary
                VStack(spacing: 8) {
                    HStack {
                        Text("\(cartItems.count) items")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(Helpers.formatCurrency(cartTotal))
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)

                    Button(action: { showCheckout = true }) {
                        Text("Cobrar \(Helpers.formatCurrency(cartTotal))")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(cartItems.isEmpty ? Color.gray : Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(cartItems.isEmpty)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Punto de Venta")
            .sheet(isPresented: $showCheckout) {
                checkoutView
            }
        }
        .onAppear {
            loadProducts()
        }
    }

    private var checkoutView: some View {
        NavigationStack {
            Form {
                Section("Productos") {
                    ForEach(cartItems) { item in
                        HStack {
                            Text(item.product.name)
                            Spacer()
                            Text("\(Int(item.quantity)) x \(Helpers.formatCurrency(item.product.salePrice))")
                            Text(Helpers.formatCurrency(item.product.salePrice * item.quantity))
                                .bold()
                        }
                    }
                }

                Section("Método de Pago") {
                    Picker("Método", selection: $selectedPayment) {
                        ForEach(paymentMethods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                }

                Section("Total") {
                    HStack {
                        Text("Total")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text(Helpers.formatCurrency(cartTotal))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.green)
                    }
                }

                Button(action: completeSale) {
                    Text("Confirmar Venta")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.green)
            }
            .navigationTitle("Confirmar Venta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showCheckout = false }
                }
            }
        }
    }

    private func addToCart(_ product: Product) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(product: product, quantity: 1))
        }
    }

    private func completeSale() {
        let saleItems = cartItems.map { item in
            SaleItem(
                id: Helpers.generateId(),
                productId: item.product.id ?? "",
                productName: item.product.name,
                quantity: item.quantity,
                unitPrice: item.product.salePrice,
                total: item.product.salePrice * item.quantity
            )
        }
        let sale = Sale(
            items: saleItems,
            subtotal: cartTotal,
            discount: 0,
            total: cartTotal,
            paymentMethod: selectedPayment,
            cashierName: UIDevice.current.name,
            createdAt: Timestamp(date: Date()),
            notes: ""
        )
        Task {
            try? await FirebaseService.shared.saveSale(sale)
            await MainActor.run {
                cartItems.removeAll()
                showCheckout = false
            }
        }
    }

    private func loadProducts() {
        Task {
            if let prods = try? await FirebaseService.shared.getProducts() {
                await MainActor.run { products = prods }
            }
        }
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let product: Product
    var quantity: Double
}
