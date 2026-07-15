import SwiftUI
import FirebaseFirestore

struct ProvidersView: View {
    @State private var providers: [Provider] = []
    @State private var searchText = ""
    @State private var showAddProvider = false
    @State private var providersListener: ListenerRegistration?

    var filteredProviders: [Provider] {
        if searchText.isEmpty { return providers }
        return providers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.nit.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search panel
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textMuted)
                    TextField("Buscar proveedor por nombre o NIT…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                // List
                if filteredProviders.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "truck.box")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textMuted)
                        Text("No hay proveedores registrados")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredProviders) { provider in
                            NavigationLink(destination: ProviderDetailView(provider: provider, onSave: {} )) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(provider.name)
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Text("NIT: \(provider.nit)")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    
                                    HStack {
                                        if !provider.contact.isEmpty {
                                            Label(provider.contact, systemImage: "person.fill")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        
                                        if !provider.phone.isEmpty {
                                            Label(provider.phone, systemImage: "phone.fill")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textMuted)
                                        }
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
            .navigationTitle("Proveedores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddProvider = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddProvider) {
                ProviderFormView(onSave: {})
            }
        }
        .onAppear {
            providersListener = FirebaseService.shared.listenProviders { list in
                self.providers = list
            }
        }
        .onDisappear {
            providersListener?.remove()
        }
    }
}

struct ProviderDetailView: View {
    @State var provider: Provider
    let onSave: () -> Void
    @State private var isEditing = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section("Información de la Empresa") {
                LabeledContent("Nombre / Razón Social", value: provider.name)
                LabeledContent("NIT", value: provider.nit)
            }

            Section("Contacto") {
                LabeledContent("Contacto Principal", value: provider.contact.isEmpty ? "No registrado" : provider.contact)
                LabeledContent("Teléfono", value: provider.phone.isEmpty ? "No registrado" : provider.phone)
                LabeledContent("Correo Electrónico", value: provider.email.isEmpty ? "No registrado" : provider.email)
            }
            
            Section {
                Button(action: { isEditing = true }) {
                    Label("Editar Proveedor", systemImage: "pencil")
                        .foregroundColor(AppColors.primary)
                }
                
                Button(role: .destructive, action: deleteProvider) {
                    Label("Eliminar Proveedor", systemImage: "trash")
                }
            }
        }
        .navigationTitle(provider.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            ProviderFormView(provider: provider, onSave: {})
        }
        .onAppear {
            if let id = provider.id {
                providerListener = FirebaseService.shared.db.collection("providers").document(id).addSnapshotListener { snapshot, _ in
                    if let updated = try? snapshot?.data(as: Provider.self) {
                        self.provider = updated
                    }
                }
            }
        }
        .onDisappear {
            providerListener?.remove()
        }
    }
    
    @State private var providerListener: ListenerRegistration?

    private func deleteProvider() {
        Task {
            if let id = provider.id {
                try? await FirebaseService.shared.deleteProvider(id)
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

struct ProviderFormView: View {
    @Environment(\.dismiss) var dismiss
    var provider: Provider? = nil
    let onSave: () -> Void

    @State private var name = ""
    @State private var nit = ""
    @State private var contact = ""
    @State private var phone = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del Proveedor") {
                    TextField("Nombre de la Empresa", text: $name)
                    TextField("NIT (ej: 800.432.109-1)", text: $nit)
                    TextField("Persona de Contacto", text: $contact)
                    TextField("Teléfono", text: $phone)
                    TextField("Correo Electrónico", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle(provider == nil ? "Agregar Proveedor" : "Editar Proveedor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveProvider() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let p = provider {
                    name = p.name
                    nit = p.nit
                    contact = p.contact
                    phone = p.phone
                    email = p.email
                }
            }
        }
    }

    private func saveProvider() {
        let p = Provider(
            id: provider?.id ?? Helpers.generateId(),
            name: name,
            nit: nit,
            contact: contact,
            phone: phone,
            email: email
        )

        Task {
            try? await FirebaseService.shared.saveProvider(p)
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
