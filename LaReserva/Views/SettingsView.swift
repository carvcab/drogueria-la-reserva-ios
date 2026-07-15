import SwiftUI

struct SettingsView: View {
    @State private var showResetAlert = false
    @State private var isConnected = false

    var body: some View {
        Form {
            Section("Información de la Aplicación") {
                LabeledContent("App", value: "\(AppConstants.appName) v\(AppConstants.appVersion)")
                LabeledContent("Razón Social", value: AppConstants.businessName)
                LabeledContent("Ubicación Principal", value: AppConstants.location)
            }

            Section("Zonas de Soporte") {
                Button(action: {
                    // Export
                }) {
                    Label("Exportar Copia de Seguridad", systemImage: "square.and.arrow.up")
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: {
                    // Import
                }) {
                    Label("Importar Copia de Seguridad", systemImage: "square.and.arrow.down")
                        .foregroundColor(AppColors.primary)
                }
            }

            Section("Zona de Peligro") {
                Button(role: .destructive, action: { showResetAlert = true }) {
                    Label("Restablecer Base de Datos", systemImage: "exclamationmark.triangle.fill")
                }
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restablecer", isPresented: $showResetAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Confirmar Restablecer", role: .destructive) {
                // Perform DB reset
            }
        } message: {
            Text("Esta acción borrará todos los datos. ¿Está seguro?")
        }
        .onAppear {
            isConnected = FirebaseService.shared.isAuthenticated
        }
    }
}
