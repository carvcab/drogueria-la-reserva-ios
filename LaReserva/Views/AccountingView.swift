import SwiftUI
import FirebaseFirestore

struct AccountingView: View {
    @State private var cashRegister = CashRegister(base: 0.0, currentStatus: "Abierta")
    @State private var cashWithdrawals: [CashWithdrawal] = []
    @State private var closings: [Closing] = []
    @State private var sales: [Sale] = []
    @State private var customerTransactions: [CustomerTransaction] = []
    @State private var returns: [Return] = []
    
    @State private var cashRegisterListener: ListenerRegistration?
    @State private var cashWithdrawalsListener: ListenerRegistration?
    @State private var closingsListener: ListenerRegistration?
    @State private var salesListener: ListenerRegistration?
    @State private var customerTransactionsListener: ListenerRegistration?
    @State private var returnsListener: ListenerRegistration?
    
    @State private var showWithdrawalDialog = false
    @State private var showClosingDialog = false
    
    // Summary values
    var todayStr: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }
    
    var todayCashSales: Double {
        sales.filter { $0.payment == "efectivo" && $0.date.hasPrefix(todayStr) && $0.returned != true }
            .reduce(0.0) { $0 + $1.total }
    }
    
    var todayAbonosCash: Double {
        customerTransactions.filter { ($0.type == "payment" || $0.type == "abono") && $0.method == "efectivo" && $0.date.hasPrefix(todayStr) }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    var todayWithdrawalsTotal: Double {
        cashWithdrawals.filter { $0.date.hasPrefix(todayStr) }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    var todayReturnsTotal: Double {
        returns.filter { $0.date.hasPrefix(todayStr) }
            .reduce(0.0) { $0 + $1.total }
    }
    
    var expectedCashInHand: Double {
        return max(0.0, cashRegister.base + todayCashSales + todayAbonosCash - todayWithdrawalsTotal - todayReturnsTotal)
    }

    var body: some View {
        NavigationStack {
            AnimatedBackground(showParticles: true) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Register Summary Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Estado de Caja")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Text(cashRegister.currentStatus == "Abierta" ? "CAJA ABIERTA" : "CAJA CERRADA")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(cashRegister.currentStatus == "Abierta" ? AppColors.primary : AppColors.danger)
                                }
                                Spacer()
                                
                                // Indicator icon
                                Image(systemName: cashRegister.currentStatus == "Abierta" ? "lock.open.fill" : "lock.fill")
                                    .font(.title)
                                    .foregroundColor(cashRegister.currentStatus == "Abierta" ? AppColors.primary : AppColors.danger)
                                    .padding(12)
                                    .background((cashRegister.currentStatus == "Abierta" ? AppColors.primary : AppColors.danger).opacity(0.12))
                                    .clipShape(Circle())
                            }
                            
                            Divider()
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Base de Apertura")
                                    Spacer()
                                    Text(Helpers.formatCurrency(cashRegister.base))
                                        .bold()
                                }
                                HStack {
                                    Text("Ventas en Efectivo Hoy")
                                    Spacer()
                                    Text("+ \(Helpers.formatCurrency(todayCashSales))")
                                        .bold()
                                        .foregroundColor(AppColors.primary)
                                }
                                HStack {
                                    Text("Abonos en Efectivo Hoy")
                                    Spacer()
                                    Text("+ \(Helpers.formatCurrency(todayAbonosCash))")
                                        .bold()
                                        .foregroundColor(AppColors.primary)
                                }
                                HStack {
                                    Text("Retiros de Caja Hoy")
                                    Spacer()
                                    Text("- \(Helpers.formatCurrency(todayWithdrawalsTotal))")
                                        .bold()
                                        .foregroundColor(AppColors.danger)
                                }
                                HStack {
                                    Text("Devoluciones Hoy")
                                    Spacer()
                                    Text("- \(Helpers.formatCurrency(todayReturnsTotal))")
                                        .bold()
                                        .foregroundColor(AppColors.danger)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Efectivo Esperado en Caja")
                                        .font(.headline)
                                    Spacer()
                                    Text(Helpers.formatCurrency(expectedCashInHand))
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.primaryLight.opacity(0.85))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1.5)
                        )
                        .padding(.horizontal)
                        .padding(.top)

                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: { showWithdrawalDialog = true }) {
                                Label("Retirar Dinero", systemImage: "arrow.down.forward.circle.fill")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.danger)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Button(action: { showClosingDialog = true }) {
                                Label("Arqueo / Cierre", systemImage: "checkmark.seal.fill")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.primaryGradient)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal)
                        
                        // Recent Cash Withdrawals
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Retiros de Caja Recientes")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            if cashWithdrawals.isEmpty {
                                Text("No se han registrado retiros hoy")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textMuted)
                                    .padding(.horizontal)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(cashWithdrawals.prefix(5)) { item in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.reason)
                                                    .font(.subheadline)
                                                    .bold()
                                                Text(item.date)
                                                    .font(.caption2)
                                                    .foregroundColor(AppColors.textMuted)
                                            }
                                            Spacer()
                                            Text("- \(Helpers.formatCurrency(item.amount))")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(AppColors.danger)
                                        }
                                        .padding()
                                        .background(AppColors.cardPink.opacity(0.85))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Historic Closings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Historial de Arqueos / Cierres")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            if closings.isEmpty {
                                Text("No hay cierres de caja registrados")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textMuted)
                                    .padding(.horizontal)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(closings.prefix(5)) { item in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.date.prefix(10))
                                                    .font(.subheadline)
                                                    .bold()
                                                HStack {
                                                    Text("Esperado: \(Helpers.formatCurrency(item.expected))")
                                                    Text("•")
                                                    Text("Real: \(Helpers.formatCurrency(item.actual))")
                                                }
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            }
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text(Helpers.formatCurrency(item.difference))
                                                    .font(.subheadline)
                                                    .bold()
                                                    .foregroundColor(item.difference < 0 ? AppColors.danger : (item.difference > 0 ? .blue : AppColors.primary))
                                                Text(item.difference < 0 ? "Faltante" : (item.difference > 0 ? "Sobrante" : "Cuadrado"))
                                                    .font(.caption2)
                                                    .foregroundColor(item.difference < 0 ? AppColors.danger : (item.difference > 0 ? .blue : AppColors.primary))
                                            }
                                        }
                                        .padding()
                                        .background(AppColors.getPastelColor(2).opacity(0.85))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .background(Color.clear)
            }
            .navigationTitle("Caja y Contabilidad")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showWithdrawalDialog) {
                CashWithdrawalFormView(onSave: {})
            }
            .sheet(isPresented: $showClosingDialog) {
                ClosingFormView(expectedCash: expectedCashInHand, currentBase: cashRegister.base, onSave: {})
            }
            .onAppear {
                startListeners()
            }
            .onDisappear {
                stopListeners()
            }
        }
    }

    private func startListeners() {
        cashRegisterListener = FirebaseService.shared.getCashRegister { register in
            self.cashRegister = register
        }
        cashWithdrawalsListener = FirebaseService.shared.listenCashWithdrawals { list in
            self.cashWithdrawals = list
        }
        closingsListener = FirebaseService.shared.listenClosings { list in
            self.closings = list
        }
        salesListener = FirebaseService.shared.listenSales { list in
            self.sales = list
        }
        customerTransactionsListener = FirebaseService.shared.db.collection("customerTransactions").order(by: "date", descending: true).addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            self.customerTransactions = docs.compactMap { try? $0.data(as: CustomerTransaction.self) }
        }
        returnsListener = FirebaseService.shared.listenReturns { list in
            self.returns = list
        }
    }

    private func stopListeners() {
        cashRegisterListener?.remove()
        cashWithdrawalsListener?.remove()
        closingsListener?.remove()
        salesListener?.remove()
        customerTransactionsListener?.remove()
        returnsListener?.remove()
    }
}

struct CashWithdrawalFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () -> Void

    @State private var amountText = ""
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalle del Retiro") {
                    HStack {
                        Text("Monto Retirado")
                        Spacer()
                        TextField("$0", text: $amountText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 140)
                    }
                    TextField("Motivo de retiro (ej: Pago de servicios, etc.)", text: $reason)
                }

                Section {
                    Button(action: saveWithdrawal) {
                        Text("Registrar Retiro de Efectivo")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.danger)
                            .cornerRadius(12)
                    }
                    .listRowInsets(EdgeInsets())
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(amountText) ?? 0 <= 0)
                }
            }
            .navigationTitle("Retirar Efectivo de Caja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func saveWithdrawal() {
        guard let amount = Double(amountText), amount > 0 else { return }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())

        let item = CashWithdrawal(
            id: Helpers.generateId(),
            date: dateStr,
            amount: amount,
            reason: reason
        )

        Task {
            try? await FirebaseService.shared.saveCashWithdrawal(item)
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}

struct ClosingFormView: View {
    @Environment(\.dismiss) var dismiss
    let expectedCash: Double
    let currentBase: Double
    let onSave: () -> Void

    @State private var actualCashText = ""
    @State private var nextBaseText = ""
    @State private var notes = ""

    var actualCash: Double {
        Double(actualCashText) ?? 0.0
    }

    var nextBase: Double {
        Double(nextBaseText) ?? 0.0
    }

    var difference: Double {
        actualCash - expectedCash
    }

    var sentToHistorical: Double {
        max(0.0, actualCash - nextBase)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Arqueo de Caja") {
                    LabeledContent("Efectivo Esperado", value: Helpers.formatCurrency(expectedCash))
                    
                    HStack {
                        Text("Efectivo Real en Mano")
                        Spacer()
                        TextField("$0", text: $actualCashText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 140)
                    }
                    
                    HStack {
                        Text("Diferencia")
                        Spacer()
                        Text(Helpers.formatCurrency(difference))
                            .bold()
                            .foregroundColor(difference < 0 ? AppColors.danger : (difference > 0 ? .blue : AppColors.primary))
                    }
                }

                Section("Base del Siguiente Turno") {
                    HStack {
                        Text("Base para Apertura Siguiente")
                        Spacer()
                        TextField("$0", text: $nextBaseText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 140)
                    }
                    
                    LabeledContent("Remanente a Depositar", value: Helpers.formatCurrency(sentToHistorical))
                }

                Section("Observaciones") {
                    TextField("Notas del cierre (opcional)", text: $notes)
                }

                Section {
                    Button(action: saveClosing) {
                        Text("Realizar Cierre de Turno")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primaryGradient)
                            .cornerRadius(12)
                    }
                    .listRowInsets(EdgeInsets())
                    .disabled(Double(actualCashText) ?? 0 <= 0 || Double(nextBaseText) ?? 0 <= 0)
                }
            }
            .navigationTitle("Cierre de Caja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                nextBaseText = String(format: "%.0f", currentBase)
            }
        }
    }

    private func saveClosing() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: Date())

        let closing = Closing(
            id: Helpers.generateId(),
            date: dateStr,
            expected: expectedCash,
            actual: actualCash,
            nextBase: nextBase,
            sentToHistorical: sentToHistorical,
            difference: difference,
            status: difference < 0 ? "Faltante" : (difference > 0 ? "Sobrante" : "Cuadrado"),
            notes: notes
        )

        Task {
            // 1. Save closing record
            try? await FirebaseService.shared.saveClosing(closing)
            
            // 2. Set new cash register base and close register
            let register = CashRegister(base: nextBase, currentStatus: "Abierta") // Open with new base
            try? await FirebaseService.shared.updateCashRegister(register)
            
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
}
