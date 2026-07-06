import SwiftUI

/// Sélecteur segmenté du design : cases séparées par un filet, la case
/// active passe en blanc sur noir. Supporte la multi-sélection (exposition).
struct SegmentedRow<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> String
    let isSelected: (Option) -> Bool
    let select: (Option) -> Void

    var body: some View {
        let selection = options.map(isSelected)
        return HStack(spacing: 1) {
            ForEach(options, id: \.self) { option in
                let selected = isSelected(option)
                Button {
                    select(option)
                } label: {
                    Text(label(option).uppercased())
                        .font(.nadirMono(11))
                        .tracking(0.66)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 2)
                        .foregroundStyle(selected ? Color.black : Color.nadirDim)
                        .background(selected ? Color.white : Color.black)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .background(Color.nadirLine)
        .border(Color.nadirLine, width: 1)
        .animation(.easeOut(duration: 0.12), value: selection)
    }
}
