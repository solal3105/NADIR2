# NADIR

Rafraîchir son logement sans climatisation : NADIR compare, heure par heure,
la température chez vous à celle du dehors et vous dit **quand ouvrir et
quand fermer** vos fenêtres. App iOS native (SwiftUI, iOS 17+), portée depuis
le design Claude Design `NADIR.dc.html`.

## Lancer

```bash
brew install xcodegen   # si besoin
xcodegen generate
open NADIR.xcodeproj    # ⌘R sur un simulateur iPhone
```

## Ce que fait l'app

- **Onboarding en 4 réglages** : ville (ou géolocalisation), inertie des murs,
  ventilation possible, exposition (une ou deux façades, logement traversant).
- **Aujourd'hui** : le conseil (« Ouvrez de 22 h à 7 h » / « Gardez fermé »)
  et une phrase qui dit quoi faire, le graphe dehors / chez vous simulé sur
  30 h avec le créneau conseillé, des **notifications** au moment d'ouvrir et
  de fermer (locales, répétées à +3 et +6 min) et la température chez vous.
  Les réglages du logement sont rangés dans « Votre logement » (feuille) et
  le détail du chiffre est replié (« D'où vient ce chiffre ? »).
- **Mi-saison : quand aérer** (automne, hiver, printemps) : « À quelle heure
  aérer sans trop refroidir ? ». NADIR conseille le moment le plus doux de la
  journée (heures éveillées) où l'air du dehors assèche le logement, la durée
  d'aération selon la ventilation (le temps de renouveler l'air une fois,
  5 à 15 min), ce qu'elle coûte en degrés comparée au plus frais, et la
  vapeur évacuée. Réglage « Que cherchez-vous ? » : automatique (rafraîchir
  dès 25 °C dehors, aérer sinon), rafraîchir ou aérer. Conseil, graphe,
  notifications, widgets et Siri suivent le mode.
- **Mode d'emploi** : les quatre moments de l'été, les deux questions
  avant d'ouvrir, le courant d'air, et l'aération le reste de l'année.
- **Comprendre** : la physique (murs éponges), la limite honnête, le résumé
  en cinq points, les sources.
- **À propos** (onglet dédié) : la démarche (NADIR ne milite pas contre
  la climatisation, il aide celles et ceux qui n'ont pas d'autre choix que de
  rafraîchir la nuit), l'honnêteté sur l'estimation (ordres de grandeur, pas
  des mesures), et son auteur Solal Gendrin (conseiller métropolitain
  écologiste à la Métropole de Lyon) avec ses projets Open Projets et
  Lyon Pocket.
- **Siri & Raccourcis** (App Intents) : « Le conseil NADIR » dicté par Siri
  (« Le verdict NADIR » marche toujours), et trois actions pour l'app
  Raccourcis : Obtenir le conseil, Faut-il ouvrir maintenant ? (condition
  d'automatisation) et Indiquer la température chez vous (alimentable par un capteur connecté HomeKit ou Matter). Pas de
  commissioning Matter direct : l'interop domotique passe par les
  automatisations Raccourcis/Maison.
- **Widgets (petit et moyen)** : la courbe en continu sur l'écran d'accueil,
  le créneau, le conseil et la notification programmée (carré vert + heure). Une entrée
  de timeline par heure fait avancer la fenêtre avec l'horloge, l'app pousse
  ses mises à jour via l'App Group, et le widget re-télécharge lui-même la
  météo quand la série ne couvre plus les 30 h à venir : jamais désynchronisé.

## Site (GitHub Pages)

Le dossier [docs/](../docs/) à la racine du dépôt contient le mini-site
statique, dans le design de l'app :

- Marketing : https://solal3105.github.io/NADIR2/
- Assistance : https://solal3105.github.io/NADIR2/assistance.html
- Confidentialité : https://solal3105.github.io/NADIR2/confidentialite.html
- Copyright : https://solal3105.github.io/NADIR2/copyright.html

(URL sensibles à la casse : le dépôt s'appelle `NADIR2`.)

Ce sont les URL d'assistance et de politique de confidentialité attendues par
l'App Store. Publication : Settings → Pages → « Deploy from a branch » →
branche `main`, dossier `/docs`.

## Architecture

```
NADIR/
├── App/            Point d'entrée SwiftUI
├── Models/         WeatherSeries, WallInertia/Ventilation, Exposure, UserProfile
├── Engine/         ThermalModel (deux nœuds air + masse, apports solaires
│                   par façade, hystérésis à pénalité solaire), ThermalAnalysis
├── Services/       WeatherService (Open-Meteo), LocationService, AlarmScheduler
├── Shared/         SharedStore (App Group, pont app ↔ widgets)
├── ViewModels/     AppModel (@Observable, @MainActor)
└── Views/          Today / Onboarding / Guide / Learn + composants et thème
NadirWidgets/       Extension WidgetKit (petit + moyen), timeline horaire
```

- **Météo** : Open-Meteo (prévisions horaires température + point de rosée,
  3 jours, fuseau du lieu), géocodage Open-Meteo. Sans réseau ni ville :
  série d'exemple.
- **Modèle thermique** : deux nœuds (air + masse) au pas horaire avec
  sous-pas, capacités EN ISO 13790, apport solaire en cloche par façade
  (est 9 h, sud 13 h, ouest 17 h 30), volets fermés = 30 % du soleil.
  À titre indicatif.
- **Persistance** : profil (réglages, ville, alarmes, température intérieure)
  dans les `UserDefaults` de l'App Group `group.com.solalgendrin.nadir`
  (`nadir.profile.v1`), partagés avec les widgets ; migration automatique
  depuis l'ancien stockage local.
- **Géolocalisation** : le géocodage inverse affiche le nom de la ville
  plutôt que « Votre position ».
- `design-reference/logic.js` : logique du design d'origine, conservée comme
  source de vérité du port.

## Crédits

- Le moteur thermique et le front-end, entre autres, ont été réalisés avec
  Claude Fable (Anthropic).
- La direction artistique et le logo sont faits main, par Solal Gendrin.
