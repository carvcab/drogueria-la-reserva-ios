import SwiftUI

struct SettingsView: View {
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Información") {
                    LabeledContent("App", value: "\(AppConstants.appName) v\(AppConstants.appVersion)")
                    LabeledContent("Negocio", value: AppConstants.businessName)
                    LabeledContent("NIT", value: AppConstants.nit)
                    LabeledContent("Ubicación", value: AppConstants.location)
                }

                Section("Firebase") {
                    LabeledContent("Proyecto", value: AppConstants.firebaseProjectId)
                    LabeledContent("Storage", value: AppConstants.firebaseStorageBucket)
                }

                Section("Sucursales") {
                    Text("Gestión de sucursales próximamente")
                        .foregroundColor(.secondary)
                }

                Section("Respaldo") {
                    Button("Exportar Datos") {
                        // TODO
                    }
                    Button("Importar Datos") {
                        // TODO
                    }
                }

                Section("Zona de Peligro") {
                    Button("Restablecer Base de Datos", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .navigationTitle("Ajustes")
            .alert("Restablecer", isPresented: $showResetAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Restablecer", role: .destructive) {}
            } message: {
                Text("Esta acción eliminará todos los datos locales. ¿Estás seguro?")
            }
        }
    }
}
