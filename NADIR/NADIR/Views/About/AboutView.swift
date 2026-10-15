import SwiftUI

/// Onglet À propos : pourquoi NADIR existe, la limite de ses chiffres, et
/// son auteur, Solal Gendrin, avec ses autres projets.
struct AboutView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                section(eyebrow: "Pourquoi cette app") {
                    (
                        Text("NADIR n’est pas contre la climatisation. ")
                            .foregroundColor(.white)
                            + Text("Je l’ai faite pour celles et ceux qui n’en ont pas, et qui doivent rafraîchir leur logement autrement : en ouvrant au bon moment.")
                    )
                }

                section(eyebrow: "Ce que valent les chiffres") {
                    (
                        Text("NADIR ne connaît pas tout de votre logement : l’isolation, le vitrage, l’étage, ce qu’il y a autour. Ses chiffres sont des ")
                            + Text("ordres de grandeur").foregroundColor(.white)
                            + Text(", pas des mesures.")
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
            SectionTitle(text: "À propos", size: 38)
            paragraph(
                Text("NADIR vous dit quand ouvrir et quand fermer vos fenêtres pour garder votre logement vivable pendant les chaleurs, et quand aérer le reste de l’année.")
            )
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .riseIn(trigger: 0, delay: 0.05)
    }

    private var author: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Qui est derrière\u{00A0}?")
                .padding(.bottom, 14)
            Text("Solal Gendrin")
                .font(.nadirSans(26, weight: .heavy))
                .tracking(-0.6)
                .foregroundStyle(.white)
            Text("Conseiller métropolitain écologiste à la Métropole de Lyon")
                .font(.nadirSans(15))
                .lineSpacing(4)
                .foregroundStyle(Color.nadirDim)
                .padding(.top, 6)
            paragraph(
                Text("Élu et développeur, je crée des outils numériques ")
                    + Text("gratuits et ouverts").foregroundColor(.white)
                    + Text(", utiles aux habitants.")
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
            Eyebrow(text: "Mes autres projets")
                .padding(.bottom, 14)

            projectCard(
                image: Image("OpenProjetsLogo"),
                imageInset: 8,
                name: "Open Projets",
                description: "La carte des projets urbains d’une collectivité, pour informer les habitants. Sans écrire une ligne de code.",
                urlLabel: "openprojets.com",
                url: URL(string: "https://openprojets.com/home")!
            )
            .padding(.bottom, 10)

            projectCard(
                image: Image("LyonPocketLogo"),
                imageInset: 0,
                name: "Lyon Pocket",
                description: "Les bus, trams et métros de Lyon en direct sur une carte, avec les perturbations. Gratuit, sans publicité, sans compte.",
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
                    Text(urlLabel)
                        .font(.nadirSans(13))
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
            Eyebrow(text: "Siri et Raccourcis")
            paragraph(
                Text("Dites « ")
                    + Text("Le conseil NADIR").foregroundColor(.white)
                    + Text(" » à Siri pour connaître le conseil du moment. Dans l’app Raccourcis, NADIR propose trois actions : ")
                    + Text("Obtenir le conseil").foregroundColor(.white)
                    + Text(", ")
                    + Text("Faut-il ouvrir maintenant\u{00A0}?").foregroundColor(.white)
                    + Text(" et ")
                    + Text("Indiquer la température chez vous").foregroundColor(.white)
                    + Text(".")
            )
            paragraph(
                Text("Avec un capteur ou des volets connectés (HomeKit, Matter), une automatisation peut, par exemple, envoyer la température de chez vous à NADIR, ou fermer les volets à l’heure conseillée.")
            )
            Link(destination: URL(string: "shortcuts://")!) {
                Text("Ouvrir Raccourcis")
                    .font(.nadirSans(15))
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
                Text("Revoir l’introduction")
                    .font(.nadirSans(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .border(Color.nadirLine, width: 1)

            Text("NADIR est gratuit, sans publicité et sans compte. Météo : Open-Meteo.")
                .font(.nadirSans(13))
                .lineSpacing(4)
                .foregroundStyle(Color.nadirDim)
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
            .font(.nadirSans(16))
            .lineSpacing(4)
            .foregroundStyle(Color.nadirSoft)
            .fixedSize(horizontal: false, vertical: true)
    }
}
