import SwiftUI
import FirebaseFirestore

struct CashWithdrawalsView: View {
    @State private var withdrawals: [CashWithdrawal] = []
    @State private var showAddWithdrawal = false
    @State private var searchText = ""
    @State private var listener: ListenerRegistration?

    var todayStr: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    var todayTotal: Double {
        withdrawals.filter { $0.date.hasPrefix(todayStr) }
            .reduce(0.0) { $0 + $1.amount }
    }

    var allTimeTotal: Double {
        withdrawals.reduce(0.0) { $0 + $1.amount }
    }

    var filteredWithdrawals: [CashWithdrawal] {
        if searchText.isEmpty { return withdrawals }
        return withdrawals.filter {
            $0.reason.localizedCaseInsensitiveContains(searchText) ||
            $0.date.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            AnimatedBackground(showParticles: true) {
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textMuted)
                        TextField("Buscar retiro por motivo o fecha…", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(10)
                    .background(Color(.systemBackground).opacity(0.85))
                    .cornerRadius(8)
                    .padding()

                    // Stat Cards
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Retirado Hoy",
                            value: Helpers.formatCurrency(todayTotal),
                            icon: "banknote.fill",
                            color: AppColors.danger,
                            backgroundColor: AppColors.cardPink
                        )
                        StatCard(
                            title: "Acumulado Total",
                            value: Helpers.formatCurrency(allTimeTotal),
                            icon: "tray.and.arrow.down.fill",
                            color: .purple,
                            backgroundColor: AppColors.getPastelColor(8)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    // Withdrawals List
                    if filteredWithdrawals.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "arrow.down.forward.circle")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textMuted)
                            Text("No hay retiros registrados")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredWithdrawals) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.down.forward.circle.fill")
                                        .foregroundColor(AppColors.danger)
                                        .padding(10)
                                        .background(AppColors.danger.opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.reason)
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar")
                                                .font(.caption2)
                                                .foregroundColor(AppColors.textMuted)
                                            Text(item.date)
                                                .font(.caption2)
                                                .foregroundColor(AppColors.textMuted)
                                        }
                                    }

                                    Spacer()

                                    Text("- \(Helpers.formatCurrency(item.amount))")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(AppColors.danger)
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(Color.white.opacity(0.85))
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let item = filteredWithdrawals[index]
                                    if let id = item.id {
                                        Task {
                                            try? await FirebaseService.shared.deleteCashWithdrawal(id)
                                        }
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
            }
            .background(Color.clear)
            .navigationTitle("Retiros de Dinero (Caja)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddWithdrawal = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddWithdrawal) {
                CashWithdrawalFormView(onSave: {})
            }
        }
        .onAppear {
            listener = FirebaseService.shared.listenCashWithdrawals { list in
                self.withdrawals = list
            }
        }
        .onDisappear {
            listener?.remove()
        }
    }
}
