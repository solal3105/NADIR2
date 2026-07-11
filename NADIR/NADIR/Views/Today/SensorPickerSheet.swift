import SwiftUI
import UIKit

/// Choix du capteur connecté qui alimentera la température intérieure :
/// sonde HomeKit ou Matter, capteur exposé par Home Assistant via son pont.
struct SensorPickerSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Capteur connecté")
                .padding(.bottom, 12)
            SectionTitle(text: "Choisir un capteur", size: 28)
                .padding(.bottom, 20)
            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .background(Color.black)
        .task { model.homeKit.start() }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.black)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var content: some View {
        if model.homeKit.isDenied {
            note(
                "NADIR n'a pas accès à vos accessoires. "
                    + "Dans Réglages, activez l'accès de NADIR à vos données Maison, puis revenez ici."
            )
            settingsLink
        } else if !model.homeKit.isLoaded {
            note("Recherche des capteurs…")
        } else if model.homeKit.sensors.isEmpty {
            note(
                "Aucun capteur de température trouvé dans votre Maison. "
                    + "Les sondes HomeKit ou Matter apparaissent ici, et Home Assistant "
                    + "peut exposer ses capteurs via son pont HomeKit. "
                    + "La sonde des HomePod n'est pas accessible aux apps : pour elle, passez "
                    + "par une automatisation Raccourcis avec « Régler la température intérieure »."
            )
        } else {
            sensorList
        }
    }

    private var sensorList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.homeKit.sensors) { sensor in
                Button {
                    model.linkSensor(sensor)
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Text(sensor.name)
                            .font(.nadirSans(15))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        if sensor.id == model.profile.sensorID {
                            Text("LIÉ")
                                .font(.nadirMono(10))
                                .tracking(0.3)
                                .foregroundStyle(Color.nadirGo)
                        }
                        Text("→")
                            .font(.nadirSans(16))
                            .foregroundStyle(Color.nadirDim)
                    }
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Utiliser \(sensor.name)")
                .accessibilityAddTraits(sensor.id == model.profile.sensorID ? .isSelected : [])
                .overlay(alignment: .bottom) { Color.nadirLine.frame(height: 1) }
            }
        }
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }

    private var settingsLink: some View {
        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
            Text("OUVRIR RÉGLAGES")
                .font(.nadirMono(12))
                .tracking(0.36)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .border(Color.nadirLine, width: 1)
        .padding(.top, 16)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.nadirMono(12))
            .lineSpacing(4)
            .foregroundStyle(Color.nadirDim)
            .fixedSize(horizontal: false, vertical: true)
    }
}
