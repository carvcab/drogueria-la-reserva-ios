import Foundation

struct Helpers {
    static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = AppConstants.locale
        f.currencySymbol = AppConstants.currencySymbol
        f.maximumFractionDigits = 0
        return f
    }()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = AppConstants.locale
        return f
    }()

    static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = AppConstants.locale
        return f
    }()

    static func formatCurrency(_ amount: Double) -> String {
        numberFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func formatDateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    static func generateId() -> String {
        UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
    }
}
