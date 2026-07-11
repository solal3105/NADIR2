import SwiftUI

/// Vos réglages : température actuelle, inertie des murs, ventilation
/// possible et exposition (une ou deux façades).
struct ControlsSection: View {
    @Environment(AppModel.self) private var model
    @State private var showSensorPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            temperatureSlider
            wallsPicker
            ventilationPicker
            exposurePicker
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var temperatureSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Quelle température fait-il chez vous ?")
                    .font(.nadirSans(14))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Text(model.indoorLabel)
                    .font(.nadirMono(15))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: model.indoorNow)
            }
            Slider(
                value: Binding(get: { model.indoorNow }, set: { model.setIndoor($0) }),
                in: 20 ... 34,
                step: 0.5,
                onEditingChanged: { model.setAdjustingIndoor($0) }
            )
            .tint(.white)
            .accessibilityLabel("Température chez vous")
            sensorRow
        }
        .padding(.bottom, 22)
        .sheet(isPresented: $showSensorPicker) {
            SensorPickerSheet()
        }
    }

    /// Vert : une mesure est arrivée et le capteur est toujours visible dans
    /// la maison. Gris : rien reçu, capteur disparu ou accès révoqué.
    private var sensorHealthy: Bool {
        model.sensorActive && model.homeKit.isMonitorAttached
    }

    /// Sous le curseur : lier un capteur connecté, ou l'état du capteur lié.
    @ViewBuilder private var sensorRow: some View {
        if model.sensorLinked {
            HStack(spacing: 8) {
                Button {
                    showSensorPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(sensorHealthy ? Color.nadirGo : Color.nadirDim)
                            .frame(width: 5, height: 5)
                        Text("Température lue sur \(model.profile.sensorName)")
                            .font(.nadirMono(10))
                            .foregroundStyle(Color.nadirDim)
                            .lineLimit(1)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Changer de capteur")
                .accessibilityValue(
                    sensorHealthy
                        ? "\(model.profile.sensorName), mesure reçue"
                        : "\(model.profile.sensorName), aucune mesure reçue"
                )
                Spacer(minLength: 8)
                Button {
                    model.unlinkSensor()
                } label: {
                    Text("DÉLIER")
                        .font(.nadirMono(10))
                        .tracking(0.3)
                        .foregroundStyle(Color.nadirDim)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Délier le capteur")
            }
        } else {
            Button {
                showSensorPicker = true
            } label: {
                Text("UTILISER UN CAPTEUR CONNECTÉ →")
                    .font(.nadirMono(10))
                    .tracking(0.3)
                    .foregroundStyle(Color.nadirDim)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Utiliser un capteur connecté")
        }
    }

    private var wallsPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            question("Vos murs sont plutôt légers, moyens ou lourds ?")
            SegmentedRow(
                options: WallInertia.allCases,
                label: \.label,
                isSelected: { $0 == model.profile.inertia },
                select: { model.set(inertia: $0) }
            )
            .padding(.bottom, 8)
            hint(model.profile.inertia.hint)
        }
        .padding(.bottom, 18)
    }

    private var ventilationPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            question("Quelle ventilation pouvez-vous faire ?")
            SegmentedRow(
                options: Ventilation.allCases,
                label: \.label,
                isSelected: { $0 == model.profile.ventilation },
                select: { model.set(ventilation: $0) }
            )
            .padding(.bottom, 8)
            hint(model.profile.ventilation.hint)
        }
        .padding(.bottom, 18)
    }

    private var exposurePicker: some View {
        let exposure = model.profile.exposure
        return VStack(alignment: .leading, spacing: 0) {
            question("Quelle exposition a votre logement ?")
            SegmentedRow(
                options: Facade.allCases,
                label: \.label,
                isSelected: { exposure.contains($0) },
                select: { model.toggleExposure($0) }
            )
            .padding(.bottom, 8)
            hint(exposure.hint)
            Text("Logement traversant ? Sélectionnez deux façades.")
                .font(.nadirMono(9.5))
                .foregroundStyle(Color.nadirLine2)
                .padding(.top, 5)
        }
    }

    private func question(_ text: String) -> some View {
        Text(text)
            .font(.nadirSans(14))
            .foregroundStyle(.white)
            .padding(.bottom, 10)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.nadirMono(11))
            .lineSpacing(3)
            .foregroundStyle(Color.nadirFaint)
    }
}

extension WallInertia {
    var hint: String {
        switch self {
        case .light: "Exemple : cloison, bois, préfabriqué"
        case .medium: "Exemple : brique creuse, parpaing"
        case .heavy: "Exemple : pierre, béton, brique pleine"
        }
    }
}

extension Ventilation {
    var hint: String {
        switch self {
        case .low: "Exemple : une fenêtre entrouverte"
        case .medium: "Exemple : une fenêtre grande ouverte"
        case .high: "Exemple : plusieurs fenêtres grand ouvertes, ou un ventilateur"
        }
    }
}

extension Facade {
    var hint: String {
        switch self {
        case .north: "Peu de soleil direct."
        case .east: "Soleil direct le matin."
        case .south: "Soleil direct en milieu de journée."
        case .west: "Soleil direct l'après-midi et en soirée."
        }
    }
}

extension Exposure {
    /// Note de traversée quand deux façades sont sélectionnées.
    var dualNote: String? {
        guard isDual else { return nil }
        return isCrossOpposite
            ? "Traversant \(label) : façades opposées, fort courant d'air possible."
            : "Traversant \(label) : logement d'angle, courant d'air possible."
    }

    var hint: String {
        dualNote ?? primary.hint
    }
}
