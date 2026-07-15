import SwiftUI
import FirebaseFirestore

struct CustomersView: View {
    @State private var customers: [Customer] = []
    @State private var allTransactions: [CustomerTransaction] = []
    @State private var searchText = ""
    @State private var showAddCustomer = false
    
    @State private var customersListener: ListenerRegistration?
    @State private var transactionsListener: ListenerRegistration?

    var filteredCustomers: [Customer] {
        if searchText.isEmpty { return customers }
        return customers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.cedula.localizedCaseInsensitiveContains(searchText)
        }
    }

    var totalOutstandingDebt: Double {
        customers.reduce(0.0) { $0 + ($1.balance ?? 0.0) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search panel
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textMuted)
                    TextField("Buscar por nombre o cédula…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                // Credit Summary Panel
                HStack(spacing: 12) {
                    StatCard(
                        title: "Deuda Total Clientes",
                        value: Helpers.formatCurrency(totalOutstandingDebt),
                        icon: "person.fill.badge.minus",
                        color: AppColors.danger,
                        backgroundColor: AppColors.cardPink
                    )
                    StatCard(
                        title: "Clientes en Lista",
                        value: "\(customers.count)",
                        icon: "person.3.fill",
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryLight
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // List
                if filteredCustomers.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textMuted)
                        Text("No hay clientes registrados")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredCustomers) { customer in
                            NavigationLink(destination: CustomerDetailView(customer: customer, transactions: allTransactions.filter { $0.customerId == customer.id }, onSave: {} )) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(customer.name)
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Text(Helpers.formatCurrency(customer.balance ?? 0.0))
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor((customer.balance ?? 0.0) > 0 ? AppColors.danger : AppColors.primary)
                                    }
                                    
                                    HStack {
                                        Label(customer.cedula, systemImage: "doc.text.fill")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        if !customer.phone.isEmpty {
                                            Label(customer.phone, systemImage: "phone.fill")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textMuted)
                                        }
                                        
                                        Spacer()
                                        
                                        if customer.allowCredit {
                                            Text("Crédito: \(Helpers.formatCurrency(customer.creditLimit))")
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(AppColors.primary.opacity(0.1))
                                                .foregroundColor(AppColors.primary)
                                                .cornerRadius(6)
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
            .navigationTitle("Clientes (Crédito)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddCustomer = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddCustomer) {
                CustomerFormView(onSave: {})
            }
        }
        .onAppear {
            customersListener = FirebaseService.shared.listenCustomers { list in
                self.customers = list
            }
            transactionsListener = FirebaseService.shared.db.collection("customerTransactions").order(by: "date", descending: true).addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self.allTransactions = docs.compactMap { try? $0.data(as: CustomerTransaction.self) }
            }
        }
        .onDisappear {
            customersListener?.remove()
            transactionsListener?.remove()
        }
    }
}

struct CustomerDetailView: View {
    @State var customer: Customer
    let transactions: [CustomerTransaction]
    let onSave: () -> Void
    @State private var isEditing = false
    @State private var showAbonoDialog = false
    @State private var abonoAmount = ""
    @State private var abonoMethod = "efectivo"
    @State private var abonoNotes = ""
    @Environment(\.dismiss) var dismiss

    let paymentMethods = ["efectivo", "tarjeta", "transferencia"]

    var body: some View {
        Form {
            Section("Información General") {
                LabeledContent("Nombre Completo", value: customer.name)
                LabeledContent("Cédula / Documento", value: customer.cedula)
                LabeledContent("Teléfono", value: customer.phone.isEmpty ? "No registrado" : customer.phone)
                LabeledContent("Dirección", value: customer.address.isEmpty ? "No registrada" : customer.address)
            }

            Section("Estado de Cuenta") {
                LabeledContent("Saldo Pendiente", value: Helpers.formatCurrency(customer.balance ?? 0.0))
                LabeledContent("Permite Crédito", value: customer.allowCredit ? "Sí" : "No")
                if customer.allowCredit {
                    LabeledContent("Límite de Crédito", value: Helpers.formatCurrency(customer.creditLimit))
                    let disponible = customer.creditLimit - (customer.balance ?? 0.0)
                    LabeledContent("Crédito Disponible", value: Helpers.formatCurrency(disponible))
                }
            }
            
            Section {
                Button(action: { showAbonoDialog = true }) {
                    Label("Registrar Abono / Pago", systemImage: "checkmark.seal.fill")
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: { isEditing = true }) {
                    Label("Editar Cliente", systemImage: "pencil")
                        .foregroundColor(.blue)
                }
                
                Button(role: .destructive, action: deleteCustomer) {
                    Label("Eliminar Cliente", systemImage: "trash")
                }
            }

            Section("Historial de Movimientos") {
                if transactions.isEmpty {
                    Text("No hay transacciones registradas")
                        .font(.caption)
                        .foregroundColor(AppColors.textMuted)
                } else {
                    ForEach(transactions) { tx in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(tx.type == "credit" ? "Crédito / Compra" : "Abono / Pago")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(tx.type == "credit" ? AppColors.danger : AppColors.primary)
                                Spacer()
                                Text("\(tx.type == "credit" ? "+" : "-") \(Helpers.formatCurrency(tx.amount))")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(tx.type == "credit" ? AppColors.danger : AppColors.primary)
                            }
                            
                            HStack {
                                Text(tx.method.uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.textMuted.opacity(0.12))
                                    .foregroundColor(AppColors.textSecondary)
                                    .cornerRadius(4)
                                
                                if !tx.notes.isEmpty {
                                    Text(tx.notes)
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textMuted)
                                }
                                
                                Spacer()
                                
                                Text(tx.date.prefix(10))
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(customer.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            CustomerFormView(customer: customer, onSave: {})
        }
        .onAppear {
            if let id = customer.id {
                customerListener = FirebaseService.shared.db.collection("customers").document(id).addSnapshotListener { snapshot, _ in
                    if let updated = try? snapshot?.data(as: Customer.self) {
                        self.customer = updated
                    }
                }
            }
        }
        .onDisappear {
            customerListener?.remove()
        }
    }
    
    @State private var customerListener: ListenerRegistration?
    
    private var abonoSheetView: some View {
        NavigationStack {
            Form {
                Section("Registrar Pago de Crédito") {
                    HStack {
                        Text("Monto Abono")
                        Spacer()
                        TextField("$0", text: $abonoAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 140)
                    }
                    Picker("Método de Pago", selection: $abonoMethod) {
                        ForEach(paymentMethods, id: \.self) { method in
                            Text(method.capitalized).tag(method)
                        }
                    }
                    TextField("Notas adicionales (opcional)", text: $abonoNotes)
                }
                
                Button(action: saveAbono) {
                    Text("Guardar Abono")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryGradient)
                        .cornerRadius(12)
                }
                .listRowInsets(EdgeInsets())
                .disabled(Double(abonoAmount) ?? 0 <= 0)
            }
            .navigationTitle("Abono de Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showAbonoDialog = false }
                }
            }
        }
    }
    
    private func saveAbono() {
        guard let amount = Double(abonoAmount), amount > 0 else { return }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())
        
        let tx = CustomerTransaction(
            id: Helpers.generateId(),
            customerId: customer.id ?? "",
            date: dateStr,
            type: "payment",
            amount: amount,
            saleId: nil,
            notes: abonoNotes.isEmpty ? "Abono a cuenta" : abonoNotes,
            method: abonoMethod
        )
        
        Task {
            try? await FirebaseService.shared.saveCustomerTransaction(tx)
            
            // Subtract from balance
            var updatedCustomer = customer
            updatedCustomer.balance = max(0.0, (customer.balance ?? 0.0) - amount)
            try? await FirebaseService.shared.saveCustomer(updatedCustomer)
            
            await MainActor.run {
                self.customer = updatedCustomer
                showAbonoDialog = false
                onSave()
            }
        }
    }

    private func deleteCustomer() {
        Task {
            if let id = customer.id {
                try? await FirebaseService.shared.deleteCustomer(id)
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            }
        }
    }
}

struct CustomerFormView: View {
    @Environment(\.dismiss) var dismiss
    var customer: Customer? = nil
    let onSave: () -> Void

    @State private var name = ""
    @State private var cedula = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var allowCredit = true
    @State private var creditLimit = 150000.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos Personales") {
                    TextField("Nombre Completo", text: $name)
                    TextField("Cédula / NIT", text: $cedula)
                    TextField("Teléfono", text: $phone)
                    TextField("Dirección", text: $address)
                }

                Section("Condiciones de Crédito") {
                    Toggle("Permitir Fiado / Crédito", isOn: $allowCredit)
                    if allowCredit {
                        HStack {
                            Text("Límite de Crédito")
                            Spacer()
                            TextField("Límite", value: $creditLimit, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle(customer == nil ? "Agregar Cliente" : "Editar Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveCustomer() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cedula.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let c = customer {
                    name = c.name
                    cedula = c.cedula
                    phone = c.phone
                    address = c.address
                    allowCredit = c.allowCredit
                    creditLimit = c.creditLimit
                }
            }
        }
    }

    private func saveCustomer() {
        let c = Customer(
            id: customer?.id ?? Helpers.generateId(),
            name: name,
            cedula: cedula,
            phone: phone,
            address: address,
            allowCredit: allowCredit,
            creditLimit: creditLimit,
            balance: customer?.balance ?? 0.0
        )

        Task {
            try? await FirebaseService.shared.saveCustomer(c)
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
