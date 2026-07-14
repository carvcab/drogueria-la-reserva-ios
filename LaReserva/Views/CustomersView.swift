import SwiftUI

struct CustomersView: View {
    @State private var customers: [Customer] = []
    @State private var searchText = ""

    var filteredCustomers: [Customer] {
        if searchText.isEmpty { return customers }
        return customers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.documentNumber.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar cliente…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                List {
                    ForEach(filteredCustomers) { customer in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(customer.name)
                                .font(.headline)
                            HStack {
                                Text(customer.documentType)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(customer.documentNumber)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Saldo: \(Helpers.formatCurrency(customer.currentBalance))")
                                    .font(.caption)
                                    .foregroundColor(customer.currentBalance > 0 ? .red : .green)
                                Spacer()
                                Text("Límite: \(Helpers.formatCurrency(customer.creditLimit))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Clientes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear { loadCustomers() }
    }

    private func loadCustomers() {
        Task {
            if let result = try? await FirebaseService.shared.getCustomers() {
                await MainActor.run { customers = result }
            }
        }
    }
}
