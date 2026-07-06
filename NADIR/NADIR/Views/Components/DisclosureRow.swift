import SwiftUI

/// Dépliant du design : question en mono avec marqueur « + / − », contenu
/// gris qui se révèle en dessous. Bordures paramétrables selon le contexte.
struct DisclosureRow<Content: View>: View {
    let title: String
    var verticalPadding: CGFloat = 11
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
                        .font(.nadirMono(12))
                        .foregroundStyle(isOpen ? Color.white : Color.nadirDim)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Text(isOpen ? "−" : "+")
                        .font(.nadirMono(15))
                        .foregroundStyle(isOpen ? Color.white : Color.nadirFaint)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, verticalPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "développé" : "replié")

            if isOpen {
                content()
                    .font(.nadirSans(13))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                    .padding(.bottom, 12)
            }
        }
        .overlay(alignment: .top) { borderColor.frame(height: 1) }
        .overlay(alignment: .bottom) {
            if showsBottomBorder { borderColor.frame(height: 1) }
        }
    }
}
