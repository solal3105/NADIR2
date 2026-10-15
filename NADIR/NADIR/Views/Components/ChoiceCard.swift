import SwiftUI

/// Carte de choix de l'onboarding : un titre et un exemple, inversée en blanc
/// quand elle est sélectionnée.
struct ChoiceCard: View {
    let title: String
    let hint: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.nadirSans(15, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.black : Color.white)
                Text(hint)
                    .font(.nadirSans(13))
                    .foregroundStyle(isSelected ? Color.black.opacity(0.6) : Color.nadirDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(isSelected ? Color.white : Color.clear)
            .border(isSelected ? Color.white : Color.nadirLine, width: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }
}
