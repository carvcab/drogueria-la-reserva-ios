import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = AppColors.primary
    var backgroundColor: Color = AppColors.primaryLight

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(color)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.12))
                .clipShape(Circle())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor.opacity(0.65))
                .background(.ultraThinMaterial)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.12), lineWidth: 1.5)
        )
    }
}
