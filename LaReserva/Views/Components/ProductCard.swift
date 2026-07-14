import SwiftUI

struct ProductCard: View {
    let product: Product
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: "pill.fill")
                    .font(.title2)
                    .foregroundColor(product.isLowStock ? .orange : .blue)
                Text(product.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                Text(Helpers.formatCurrency(product.salePrice))
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.green)
                if product.isLowStock {
                    Text("Stock: \(Int(product.quantity))")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
