import SwiftUI

struct SaleItemRow: View {
    let sale: Sale

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(sale.items.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(sale.paymentMethod)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Helpers.formatCurrency(sale.total))
                    .font(.headline)
                    .bold()
                if let date = sale.createdAt?.dateValue() {
                    Text(Helpers.formatDateTime(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}
