import SwiftUI

struct ProvidersView: View {
    @State private var providers: [Provider] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(providers) { provider in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.name)
                            .font(.headline)
                        Text(provider.contactName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(provider.phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Proveedores")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear { loadProviders() }
    }

    private func loadProviders() {
        Task {
            if let result = try? await FirebaseService.shared.getProviders() {
                await MainActor.run { providers = result }
            }
        }
    }
}
