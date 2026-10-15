import SwiftUI

/// Question dépliable : la question en clair avec un marqueur « + / − »,
/// la réponse en gris qui se révèle en dessous.
struct DisclosureRow<Content: View>: View {
    let title: String
    var verticalPadding: CGFloat = 12
    var borderColor: Color = .nadirLine
    var showsBottomBorder = false
    @ViewBuilder let content: () -> Content

    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) { isOpen.toggle() }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(title)
                        .font(.nadirSans(15, weight: .medium))
                        .foregroundStyle(isOpen ? Color.white : Color.nadirSoft)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Text(isOpen ? "−" : "+")
                        .font(.nadirSans(18))
                        .foregroundStyle(isOpen ? Color.white : Color.nadirDim)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, verticalPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "développé" : "replié")

            if isOpen {
                content()
                    .font(.nadirSans(15))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                    .padding(.bottom, 14)
            }
        }
        .overlay(alignment: .top) { borderColor.frame(height: 1) }
        .overlay(alignment: .bottom) {
            if showsBottomBorder { borderColor.frame(height: 1) }
        }
    }
}

/// Section repliable de l'écran Aujourd'hui : un titre, « Voir » / « Fermer »,
/// et le contenu en dessous.
struct ExpandableSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isOpen.toggle() }
            } label: {
                HStack(spacing: 16) {
                    Text(title)
                        .font(.nadirSans(16, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Text(isOpen ? "Fermer" : "Voir")
                        .font(.nadirSans(14))
                        .foregroundStyle(Color.nadirSoft)
                }
                .padding(.vertical, 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "développé" : "replié")

            if isOpen {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }
}
