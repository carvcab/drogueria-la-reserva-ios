import SwiftUI

struct InventoryView: View {
    @State private var products: [Product] = []
    @State private var searchText = ""
    @State private var filterOption = "Todos"

    let filterOptions = ["Todos", "Stock Crítico", "Sin Stock"]

    var filteredProducts: [Product] {
        var result = products
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.barcode.localizedCaseInsensitiveContains(searchText)
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
            VStack(spacing: 0) {
                // Search & Filter
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Buscar producto…", text: $searchText)
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

                List {
                    ForEach(filteredProducts) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(.headline)
                                HStack {
                                    Text("Stock: \(Int(product.quantity)) \(product.unit)")
                                        .font(.caption)
                                        .foregroundColor(product.isLowStock ? .red : .secondary)
                                    Spacer()
                                    Text(Helpers.formatCurrency(product.salePrice))
                                        .font(.caption)
                                        .bold()
                                }
                                if product.isLowStock {
                                    Label("Stock crítico", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Inventario")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            loadProducts()
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

struct ProductDetailView: View {
    let product: Product

    var body: some View {
        Form {
            Section("Información") {
                LabeledContent("Nombre", value: product.name)
                LabeledContent("Código", value: product.barcode)
                LabeledContent("Categoría", value: product.category)
                LabeledContent("Unidad", value: product.unit)
            }

            Section("Inventario") {
                LabeledContent("Stock Actual", value: "\(Int(product.quantity))")
                LabeledContent("Stock Mínimo", value: "\(Int(product.minStock))")
                LabeledContent("Estado", value: product.isOutOfStock ? "Sin Stock" : product.isLowStock ? "Stock Crítico" : "Normal")
            }

            Section("Precios") {
                LabeledContent("Costo", value: Helpers.formatCurrency(product.costPrice))
                LabeledContent("Venta", value: Helpers.formatCurrency(product.salePrice))
                LabeledContent("Margen", value: "\(Int((product.salePrice - product.costPrice) / product.costPrice * 100))%")
            }

            if let provider = product.providerName {
                Section("Proveedor") {
                    Text(provider)
                }
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
