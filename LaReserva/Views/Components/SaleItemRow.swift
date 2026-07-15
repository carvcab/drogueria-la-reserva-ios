import SwiftUI

struct SaleItemRow: View {
    let sale: Sale

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(sale.id?.prefix(8) ?? "Venta")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(AppColors.primary)
                
                Text(sale.items.map { "\($0.qty)x \($0.name)" }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                Text(sale.payment.capitalized)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(AppColors.primary.opacity(0.12))
                    .foregroundColor(AppColors.primary)
                    .cornerRadius(4)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Helpers.formatCurrency(sale.total))
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(AppColors.textPrimary)
                
                Text(sale.date)
                    .font(.system(size: 8))
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.primaryLight.opacity(0.65))
                .background(.ultraThinMaterial)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.primary.opacity(0.08), lineWidth: 1.0)
        )
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}
