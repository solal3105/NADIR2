/*
 * NADIR — moteur du Labo 3D : le même modèle thermique à deux nœuds que
 * l'app (engine.js, port vérifié du Swift), généralisé à une géométrie
 * paramétrable : surface, épaisseur des murs (κ continue), fenêtres par mur,
 * orientation libre, soleil géométrique continu.
 *
 * Structure d'intégration identique : Euler explicite, 10 sous-pas de 6 min,
 * hystérésis −0,75 / −0,25 °C, pénalité solaire en °C équivalents, état
 * initial de la masse résolu à l'équilibre. Calibré pour retrouver l'app :
 * avec 20 m², murs moyens, 2 m² de vitrage plein sud et 8 vol/h, les
 * conductances et les pics solaires retombent sur les valeurs du modèle iOS.
 *
 * Sans dépendance ni DOM : window.NadirLab dans le navigateur,
 * module.exports en Node pour les tests.
 */
(function () {
  'use strict';

  // --- Constantes partagées avec le modèle de l'app -----------------------
  var RHO_CP = 1206;          // ρ·cp de l'air, J/(m³·K)
  var HEIGHT = 2.5;           // m, hauteur sous plafond
  var FURNITURE_PER_M2 = 4500; // J/K par m² : mobilier léger (20 m² → 90 kJ/K)
  var ENVELOPE_PER_M2 = 2.5;  // W/K par m² de plancher (20 m² → 50 W/K)
  var INTERNAL_GAINS = 150;   // W
  var SHADE_FACTOR = 0.3;     // part du soleil passant volets fermés
  var SUBSTEPS = 10;
  var OPEN_THRESHOLD = 0.75;  // °C
  var CLOSE_THRESHOLD = 0.25; // °C
  var WINDOW_HEIGHT = 1.2;    // m, hauteur de vitrage
  var WINDOW_WIDTHS = [0, 1.2, 2.4]; // m : aucune / petite / grande
  var REF_GLAZING = 2.0;      // m² : référence du modèle app (point virtuel
                              // entre « petite » 1,44 m² et « grande » 2,88 m²)

  // Soleil schématique d'été : lever 5 h 30, coucher 21 h 30, 62° au zénith.
  // Sur une façade VERTICALE, l'éclairement direct vaut
  // DNI(élévation) × cos(élévation) × cos(Δazimut) : le soleil rasant du
  // soir frappe une fenêtre ouest plus fort que le soleil haut de midi ne
  // frappe une fenêtre sud — c'est le sur-chauffage classique des pièces à
  // l'ouest. DNI ≈ I_DIR·√(sin élévation) (transparence atmosphérique).
  // I_DIR calibré pour ≈ 650 W sur 2 m² plein sud à 13 h 30 (modèle app).
  var DAY_START = 5.5, DAY_END = 21.5;
  var MAX_ELEVATION = 62 * Math.PI / 180;
  var I_DIR = 740;            // W/m² de vitrage (DNI de référence)
  var I_DIFF = 60;            // W/m² de vitrage, ciel

  var DEG = Math.PI / 180;

  /** κ continue selon l'épaisseur des murs (m) : 8 cm → 90, 40 cm → 280 kJ/m²K.
      Encadre les classes EN ISO 13790 (léger 110 / moyen 165 / lourd 260). */
  function kappaOf(thickness) {
    var t = Math.min(0.40, Math.max(0.08, thickness));
    return 90000 + (t - 0.08) / 0.32 * 190000;
  }

  /** Classe ISO la plus proche, pour l'affichage. */
  function inertiaClassOf(thickness) {
    var k = kappaOf(thickness);
    var classes = [[110000, 'légers'], [165000, 'moyens'], [260000, 'lourds']];
    var best = classes[0];
    for (var i = 1; i < classes.length; i++) {
      if (Math.abs(classes[i][0] - k) < Math.abs(best[0] - k)) best = classes[i];
    }
    return best[1];
  }

  /** Position du soleil à l'heure locale h : { azimuth, elevation } en
      radians, elevation < 0 la nuit. Azimut : 0 = nord, 90° = est. */
  function sunAt(hour) {
    var f = (hour - DAY_START) / (DAY_END - DAY_START);
    if (f < 0 || f > 1) return { azimuth: 0, elevation: -0.2 };
    return {
      azimuth: (75 + f * 210) * DEG,
      elevation: Math.sin(Math.PI * f) * MAX_ELEVATION,
    };
  }

  /** Surface vitrée d'un mur (m²) selon son niveau 0/1/2. */
  function glazingOf(level) {
    return WINDOW_WIDTHS[level] * WINDOW_HEIGHT;
  }

  /** Dérive les grandeurs physiques d'un jeu de paramètres du labo.
      params = { area (m²), thickness (m), achBase (vol/h), orientation (°),
                 windows: [0|1|2 ×4] (mur i face à orientation + i·90°),
                 indoorNow (°C) } */
  function derive(params) {
    var area = params.area;
    var volume = area * HEIGHT;
    var kappa = kappaOf(params.thickness);

    var wallAz = [];
    var glazing = [];
    var totalGlazing = 0;
    for (var i = 0; i < 4; i++) {
      wallAz.push(((params.orientation + i * 90) % 360 + 360) % 360);
      var g = glazingOf(params.windows[i] || 0);
      glazing.push(g);
      totalGlazing += g;
    }

    // Courant d'air selon la disposition réelle des fenêtres : deux murs
    // opposés → traversée franche (×1,8) ; deux murs différents → logement
    // d'angle (×1,5) ; un seul mur → ×1 (mêmes facteurs que l'app).
    var withWindows = [];
    for (i = 0; i < 4; i++) if (glazing[i] > 0) withWindows.push(i);
    var cross = 1.0;
    if (withWindows.length > 1) {
      cross = 1.5;
      for (i = 0; i < withWindows.length; i++) {
        for (var j = i + 1; j < withWindows.length; j++) {
          if ((withWindows[j] - withWindows[i]) % 2 === 0) cross = 1.8;
        }
      }
    }

    // Le renouvellement d'air croît avec la surface ouvrante (référence
    // 2 m² = les 3/8/15 vol/h du modèle app).
    var ach = totalGlazing > 0
      ? Math.min(30, params.achBase * Math.sqrt(totalGlazing / REF_GLAZING))
      : 0;

    return {
      volume: volume,
      kappa: kappa,
      airCapacity: RHO_CP * volume + FURNITURE_PER_M2 * area,
      massCapacity: kappa * area,
      airMassCoupling: 15 * area,            // 300 W/K à 20 m², ∝ parois
      envelope: ENVELOPE_PER_M2 * area,
      ventilationConductance: RHO_CP * ach * cross * volume / 3600,
      wallAz: wallAz,
      glazing: glazing,
      totalGlazing: totalGlazing,
      cross: cross,
      ach: ach,
    };
  }

  /** Apport solaire total (W) à l'heure locale h, pour la géométrie dérivée. */
  function solarGains(hour, d) {
    var sun = sunAt(hour);
    if (sun.elevation <= 0 || d.totalGlazing === 0) return 0;
    var sinE = Math.sin(sun.elevation);
    var dni = I_DIR * Math.sqrt(sinE);
    var gains = d.totalGlazing * I_DIFF * Math.sqrt(sinE);
    for (var i = 0; i < 4; i++) {
      if (d.glazing[i] === 0) continue;
      var incidence = Math.cos(sun.elevation) * Math.cos(sun.azimuth - d.wallAz[i] * DEG);
      if (incidence <= 0) continue;
      gains += d.glazing[i] * dni * incidence;
    }
    return gains;
  }

  /** Simule la pièce du labo sur la série météo.
      series = { outdoor: number[], dewPoint: number[], hours: number[] }
      (hours = heure locale 0–23 de chaque index, fournie par l'appelant).
      Retourne { indoor, mass, isOpen, runs, airFine, massFine, ... } —
      airFine/massFine : un point par sous-pas, pour une lecture fluide. */
  function simulate(series, params) {
    var n = series.outdoor.length;
    if (n === 0) {
      return {
        indoor: [], mass: [], isOpen: [], runs: [],
        airFine: [], massFine: [], solar: [],
        coolestIndex: 0, peakIndex: 0, indoorMinIndex: 0,
        coolerAtPeak: 0, indoorMin: params.indoorNow, derived: derive(params),
      };
    }
    var d = derive(params);
    // Sous-pas adaptatifs : avec plusieurs grandes fenêtres, H_vent devient
    // énorme et la constante de temps de l'air passe sous les 6 min du pas
    // standard — Euler explicite divergerait. On resserre le pas pour rester
    // à dt ≤ C/(2H), en multiple de 10 pour garder 10 échantillons fins/h.
    var hAir = d.envelope + d.ventilationConductance + d.airMassCoupling;
    var substeps = Math.max(SUBSTEPS,
      Math.ceil((2 * 3600 * hAir / d.airCapacity) / 10) * 10);
    var record = substeps / SUBSTEPS;
    var dt = 3600.0 / substeps;
    var canOpen = d.totalGlazing > 0 && d.ventilationConductance > 0;

    var initialGains = INTERNAL_GAINS
      + SHADE_FACTOR * solarGains(series.hours[0], d);
    var airTemp = params.indoorNow;
    var massTemp = params.indoorNow
      - (d.envelope * (series.outdoor[0] - params.indoorNow) + initialGains)
        / d.airMassCoupling;

    var isOpen = false;
    var indoor = [airTemp];
    var mass = [massTemp];
    var airFine = [airTemp];
    var massFine = [massTemp];
    var open = [];
    var solar = [];

    for (var i = 0; i < n; i++) {
      var sol = solarGains(series.hours[i], d);
      solar.push(sol);
      if (canOpen) {
        var penalty = (1 - SHADE_FACTOR) * sol / d.ventilationConductance;
        if (isOpen) {
          if (series.outdoor[i] > airTemp - CLOSE_THRESHOLD - penalty) isOpen = false;
        } else {
          if (series.outdoor[i] < airTemp - OPEN_THRESHOLD - penalty) isOpen = true;
        }
      }
      open.push(isOpen);
      if (i === n - 1) break;

      var gains = INTERNAL_GAINS + (isOpen ? 1 : SHADE_FACTOR) * sol;
      var conductance = d.envelope + (isOpen ? d.ventilationConductance : 0);
      for (var s = 0; s < substeps; s++) {
        var dAir = (dt / d.airCapacity)
          * (conductance * (series.outdoor[i] - airTemp)
            + d.airMassCoupling * (massTemp - airTemp)
            + gains);
        var dMass = (dt / d.massCapacity) * (d.airMassCoupling * (airTemp - massTemp));
        airTemp += dAir;
        massTemp += dMass;
        if ((s + 1) % record === 0) {
          airFine.push(airTemp);
          massFine.push(massTemp);
        }
      }
      indoor.push(airTemp);
      mass.push(massTemp);
    }

    var runs = [];
    var start = -1;
    for (i = 0; i < open.length; i++) {
      if (open[i]) {
        if (start < 0) start = i;
      } else if (start >= 0) {
        runs.push([start, i - 1]);
        start = -1;
      }
    }
    if (start >= 0) runs.push([start, open.length - 1]);

    var outdoor = series.outdoor;
    var coolestIndex = 0;
    for (i = 1; i < n; i++) if (outdoor[i] < outdoor[coolestIndex]) coolestIndex = i;
    var firstOpen = runs.length ? runs[0][0] : 0;
    var peakIndex = firstOpen;
    for (i = firstOpen; i < n; i++) {
      if (outdoor[i] >= outdoor[peakIndex]) peakIndex = i;
    }
    var indoorMinIndex = 0;
    for (i = 1; i < indoor.length; i++) {
      if (indoor[i] < indoor[indoorMinIndex]) indoorMinIndex = i;
    }

    return {
      indoor: indoor, mass: mass, isOpen: open, runs: runs,
      airFine: airFine, massFine: massFine, solar: solar,
      coolestIndex: coolestIndex, peakIndex: peakIndex,
      indoorMinIndex: indoorMinIndex,
      coolerAtPeak: Math.max(0, outdoor[peakIndex] - indoor[peakIndex]),
      indoorMin: indoor[indoorMinIndex],
      derived: d,
    };
  }

  /** Température de l'air à l'instant continu t (en heures depuis le début
      de la série), lue dans la grille fine. */
  function sampleFine(fine, tHours) {
    if (!fine.length) return 0;
    var x = Math.min(fine.length - 1, Math.max(0, tHours * SUBSTEPS));
    var i = Math.floor(x);
    var f = x - i;
    if (i >= fine.length - 1) return fine[fine.length - 1];
    return fine[i] + (fine[i + 1] - fine[i]) * f;
  }

  var NadirLab = {
    HEIGHT: HEIGHT, SUBSTEPS: SUBSTEPS,
    WINDOW_HEIGHT: WINDOW_HEIGHT, WINDOW_WIDTHS: WINDOW_WIDTHS,
    DAY_START: DAY_START, DAY_END: DAY_END,
    kappaOf: kappaOf, inertiaClassOf: inertiaClassOf,
    sunAt: sunAt, glazingOf: glazingOf,
    derive: derive, solarGains: solarGains,
    simulate: simulate, sampleFine: sampleFine,
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = NadirLab;
  if (typeof window !== 'undefined') window.NadirLab = NadirLab;
})();
