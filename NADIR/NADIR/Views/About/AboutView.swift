import SwiftUI

/// Onglet À propos : la démarche de NADIR, l'honnêteté sur l'estimation,
/// et son auteur, Solal Gendrin, avec ses autres projets.
struct AboutView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                section(eyebrow: "La démarche") {
                    (
                        Text("NADIR ne milite pas contre la climatisation. ")
                            .foregroundColor(.white)
                            + Text("J'ai conçu cette app pour celles et ceux qui n'ont pas d'autre choix que de rafraîchir leur logement la nuit, et pour les aider à décider au bon moment pendant les périodes chaudes.")
                    )
                }

                section(eyebrow: "L'estimation") {
                    (
                        Text("Impossible de connaître toutes les données d'un logement réel : isolation, vitrage, étage, environnement, micro-climat… Les chiffres de NADIR varient avec tous ces facteurs. Ils donnent ")
                            + Text("une estimation, un ordre de grandeur").foregroundColor(.white)
                            + Text(", pas une mesure.")
                    )
                }

                author
                projects
                automations
                footer
            }
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "L'app & son auteur")
            SectionTitle(text: "À propos", size: 44)
                .padding(.top, 10)
            paragraph(
                Text("Savoir quand ouvrir et quand fermer ses fenêtres, pour garder son logement vivable pendant les chaleurs.")
            )
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .riseIn(trigger: 0, delay: 0.05)
    }

    private var author: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Qui est derrière ?")
                .padding(.bottom, 14)
            Text("SOLAL GENDRIN")
                .font(.nadirSans(28, weight: .heavy))
                .tracking(-0.8)
                .foregroundStyle(.white)
            Text("Conseiller métropolitain écologiste\nà la Métropole de Lyon")
                .font(.nadirSans(15))
                .lineSpacing(4)
                .foregroundStyle(Color.nadirDim)
                .padding(.top, 8)
            paragraph(
                Text("Élu et développeur, je conçois des outils numériques ")
                    + Text("gratuits et ouverts").foregroundColor(.white)
                    + Text(" au service des habitants.")
            )
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .overlay(alignment: .top) { Color.nadirLine2.frame(height: 1) }
        .padding(.top, 24)
    }

    private var projects: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Mes projets")
                .padding(.bottom, 14)

            projectCard(
                image: Image("OpenProjetsLogo"),
                imageInset: 8,
                name: "Open Projets",
                description: "La carte interactive des projets urbains d'une collectivité : publier et informer les habitants, sans une ligne de code.",
                urlLabel: "openprojets.com",
                url: URL(string: "https://openprojets.com/home")!
            )
            .padding(.bottom, 10)

            projectCard(
                image: Image("LyonPocketLogo"),
                imageInset: 0,
                name: "Lyon Pocket",
                description: "Les transports lyonnais en direct sur la carte : bus, tram, métro, perturbations. Gratuit, sans pub, sans compte.",
                urlLabel: "lyon-pocket.netlify.app",
                url: URL(string: "https://lyon-pocket.netlify.app")!
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    private func projectCard(
        image: Image,
        imageInset: CGFloat,
        name: String,
        description: String,
        urlLabel: String,
        url: URL
    ) -> some View {
        Link(destination: url) {
            HStack(alignment: .top, spacing: 14) {
                image
                    .resizable()
                    .scaledToFit()
                    .padding(imageInset)
                    .frame(width: 52, height: 52)
                    .background(Color.nadirHairline)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.nadirSans(17, weight: .bold))
                            .tracking(-0.17)
                            .foregroundStyle(.white)
                        Spacer(minLength: 0)
                        Text("→")
                            .font(.nadirSans(15))
                            .foregroundStyle(Color.nadirFaint)
                    }
                    Text(description)
                        .font(.nadirSans(13))
                        .lineSpacing(3)
                        .foregroundStyle(Color.nadirDim)
                        .multilineTextAlignment(.leading)
                    Text(urlLabel.uppercased())
                        .font(.nadirMono(10))
                        .tracking(0.5)
                        .foregroundStyle(Color.nadirGo)
                        .padding(.top, 3)
                }
            }
            .padding(14)
            .background(Color(white: 8 / 255))
            .border(Color.nadirLine, width: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var automations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Siri & automatisations")
            paragraph(
                Text("Demandez « ")
                    + Text("le verdict NADIR").foregroundColor(.white)
                    + Text(" » à Siri, ou utilisez les actions de l'app Raccourcis : ")
                    + Text("Obtenir le verdict").foregroundColor(.white)
                    + Text(", ")
                    + Text("Faut-il ouvrir maintenant ?").foregroundColor(.white)
                    + Text(" et ")
                    + Text("Régler la température intérieure").foregroundColor(.white)
                    + Text(".")
            )
            paragraph(
                Text("Avec un capteur ou des volets connectés (HomeKit, Matter), une automatisation peut envoyer à NADIR la température mesurée chez vous, ou agir sur vos équipements selon le verdict.")
            )
            Link(destination: URL(string: "shortcuts://")!) {
                Text("OUVRIR RACCOURCIS")
                    .font(.nadirMono(12))
                    .tracking(0.36)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .border(Color.nadirLine, width: 1)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 28)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                model.replayOnboarding()
            } label: {
                Text("REVOIR L'INTRODUCTION")
                    .font(.nadirMono(12))
                    .tracking(0.36)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .border(Color.nadirLine, width: 1)

            Text("NADIR est gratuit, sans pub et sans compte. Météo : Open-Meteo.")
                .font(.nadirMono(10))
                .lineSpacing(5)
                .foregroundStyle(Color.nadirLine2)
                .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    // MARK: - Helpers

    private func section(eyebrow: String, @ViewBuilder content: () -> Text) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: eyebrow)
            paragraph(content())
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 24)
    }

    private func paragraph(_ text: Text) -> some View {
        text
            .font(.nadirSans(15))
            .lineSpacing(4)
            .foregroundStyle(Color.nadirDim)
            .fixedSize(horizontal: false, vertical: true)
    }
}
