import Foundation

struct AppConstants {
    static let appName = "La Reserva"
    static let appVersion = "8.7.0"
    static let businessName = "Droguería La Reserva"
    static let nit = "800.432.109-1"
    static let location = "Gramalote, N.S."

    static let currencySymbol = "$"
    static let locale = Locale(identifier: "es-CO")

    static let firebaseApiKey = "AIzaSyBXscbbCxZrK_CPJRuqKimfuP0u-dILTy0"
    static let firebaseProjectId = "drogeria-e7601"
    static let firebaseStorageBucket = "drogeria-e7601.firebasestorage.app"
    static let firebaseMessagingSenderId = "756439672278"
    static let firebaseAppId = "1:756439672278:ios:9d9eb4e5fc9c3a088fb077"

    static let firestoreCollections = [
        "products", "providers", "sales", "purchases", "returns",
        "customers", "customerTransactions", "cashRegister",
        "withdrawals", "ownConsumptions", "settings", "heldCarts",
        "closings", "cashWithdrawals"
    ]
}
