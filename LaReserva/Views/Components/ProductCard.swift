import SwiftUI

struct ProductCard: View {
    let product: Product
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "pill.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(product.isOutOfStock ? AppColors.textMuted : (product.isLowStock ? AppColors.danger : AppColors.primary))
                        .padding(5)
                        .background((product.isOutOfStock ? AppColors.textMuted : (product.isLowStock ? AppColors.danger : AppColors.primary)).opacity(0.1))
                        .clipShape(Circle())
                    Spacer()
                    if product.isOutOfStock {
                        Text("Agotado")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AppColors.danger)
                            .cornerRadius(4)
                    } else if product.isLowStock {
                        Text("Bajo")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AppColors.danger)
                            .cornerRadius(4)
                    }
                }
                
                Text(product.name)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(height: 28, alignment: .topLeading)
                
                Text(product.category)
                    .font(.system(size: 8))
                    .foregroundColor(AppColors.textMuted)
                    .lineLimit(1)
                
                HStack {
                    Text(Helpers.formatCurrency(product.price))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.primary)
                    Spacer()
                    Text("\(product.stock) u")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(product.isOutOfStock ? AppColors.danger : (product.isLowStock ? AppColors.danger : AppColors.textSecondary))
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(product.isOutOfStock ? Color.gray.opacity(0.2) : (product.isLowStock ? AppColors.cardPink : AppColors.primaryLight).opacity(0.7))
                    .background(.ultraThinMaterial)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke((product.isOutOfStock ? Color.gray : (product.isLowStock ? AppColors.danger : AppColors.primary)).opacity(0.1), lineWidth: 1.0)
            )
        }
        .opacity(product.isOutOfStock ? 0.5 : 1.0)
        .disabled(product.isOutOfStock)
    }
}
