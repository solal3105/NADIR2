/*
 * NADIR — moteur thermique, port JavaScript fidèle de l'app iOS
 * (ThermalModel.swift + ThermalAnalysis.swift + HomeSettings.swift +
 * Exposure.swift + WeatherSeries.swift). Mêmes constantes, mêmes équations,
 * mêmes seuils : la version web calcule exactement la même courbe.
 *
 * Aucune dépendance, aucun accès DOM : utilisable dans le navigateur
 * (window.NadirEngine) comme dans Node (module.exports) pour les tests.
 */
(function () {
  'use strict';

  // --- Constantes du modèle (ThermalModel.swift) -------------------------
  const FLOOR_AREA = 20;                 // m²
  const VOLUME = 50;                     // m³
  const AIR_HEAT_CAPACITY_PER_VOLUME = 1206; // ρ·cp de l'air, J/(m³·K)
  const AIR_NODE_CAPACITY = 150000;      // J/K : air + mobilier léger
  const AIR_MASS_COUPLING = 300;         // W/K
  const ENVELOPE_LOSS = 50;              // W/K : enveloppe + infiltration
  const INTERNAL_GAINS = 150;            // W : occupants + appareils
  const DIRECT_SOLAR = 650;              // W : pic de direct sur une façade
  const DIFFUSE_SOLAR = 120;             // W : pic de diffus, toutes façades
  const SHADE_FACTOR = 0.3;              // part du soleil passant les volets fermés
  const SUBSTEPS = 10;                   // sous-pas horaires
  const OPEN_THRESHOLD = 0.75;           // °C sous l'intérieur pour ouvrir
  const CLOSE_THRESHOLD = 0.25;          // °C sous l'intérieur pour refermer

  // --- Réglages (HomeSettings.swift) -------------------------------------
  /** Capacité interne surfacique κ, J/(m²·K) — classes EN ISO 13790. */
  const WALL_KAPPA = { light: 110000, medium: 165000, heavy: 260000 };
  const WALL_LABEL = { light: 'légers', medium: 'moyens', heavy: 'lourds' };

  /** Renouvellements d'air par heure, fenêtre ouverte. */
  const VENT_ACH = { low: 3, medium: 8, high: 15 };
  const VENT_LABEL = { low: 'faible', medium: 'moyenne', high: 'forte' };

  // --- Façades (Exposure.swift) -------------------------------------------
  /** Pic de soleil direct (heure locale) et demi-largeur de cloche (h). */
  const FACADES = {
    north: { peak: null, width: 0, label: 'nord', title: 'Nord' },
    east: { peak: 9, width: 4, label: 'est', title: 'Est' },
    south: { peak: 13, width: 4.5, label: 'sud', title: 'Sud' },
    west: { peak: 17.5, width: 4.5, label: 'ouest', title: 'Ouest' },
  };
  const FACADE_ORDER = ['north', 'east', 'south', 'west'];
  const OPPOSITE = { north: 'south', south: 'north', east: 'west', west: 'east' };

  /** exposure = { primary: 'south', secondary: null | 'east' | ... } */
  function isDual(exposure) {
    return !!exposure.secondary && exposure.secondary !== exposure.primary;
  }
  function facadesOf(exposure) {
    return isDual(exposure) ? [exposure.primary, exposure.secondary] : [exposure.primary];
  }
  function isCrossOpposite(exposure) {
    return isDual(exposure) && exposure.secondary === OPPOSITE[exposure.primary];
  }
  function exposureContains(exposure, facade) {
    return facadesOf(exposure).indexOf(facade) !== -1;
  }
  function exposureLabel(exposure) {
    return isDual(exposure)
      ? FACADES[exposure.primary].title + ' + ' + FACADES[exposure.secondary].title
      : FACADES[exposure.primary].title;
  }
  /** Coche/décoche une façade : jamais zéro sélection, deux au maximum
      (la plus ancienne est évincée). Retourne la nouvelle exposition. */
  function toggleExposure(exposure, facade) {
    const selection = facadesOf(exposure).slice();
    const index = selection.indexOf(facade);
    if (index !== -1) {
      if (selection.length > 1) selection.splice(index, 1);
    } else {
      selection.push(facade);
      if (selection.length > 2) selection.shift();
    }
    return { primary: selection[0], secondary: selection.length > 1 ? selection[1] : null };
  }

  // --- Série météo (WeatherSeries.swift) ----------------------------------
  // series = { times: number[] (ms epoch), outdoor: number[], dewPoint: number[],
  //            place: string, timeZone: string (IANA), isDemo: boolean }

  const hourFormatters = {};
  function hourFormatter(timeZone) {
    if (!hourFormatters[timeZone]) {
      try {
        hourFormatters[timeZone] = new Intl.DateTimeFormat('fr-FR', {
          hour: 'numeric', hourCycle: 'h23', timeZone: timeZone,
        });
      } catch (e) {
        hourFormatters[timeZone] = new Intl.DateTimeFormat('fr-FR', {
          hour: 'numeric', hourCycle: 'h23',
        });
      }
    }
    return hourFormatters[timeZone];
  }

  /** Heure locale du lieu (0–23) pour un index de la série. */
  function hourAt(series, index) {
    const parts = hourFormatter(series.timeZone).formatToParts(new Date(series.times[index]));
    for (let i = 0; i < parts.length; i++) {
      if (parts[i].type === 'hour') return parseInt(parts[i].value, 10) % 24;
    }
    return new Date(series.times[index]).getHours();
  }

  /** Étiquette d'heure façon « 06h », dans le fuseau du lieu. */
  function hourLabel(series, index) {
    return pad2(hourAt(series, index)) + 'h';
  }

  /** Fenêtre de simulation : démarre à l'heure courante (incluse) et couvre
      jusqu'à 30 h — assez pour le pic de demain après-midi. */
  function windowSeries(series, nowMs, maxHours) {
    if (maxHours === undefined) maxHours = 30;
    let i0 = series.times.findIndex(function (t) { return t >= nowMs; });
    if (i0 === -1) i0 = 0;
    i0 = Math.max(0, i0 - 1);
    const n = Math.min(maxHours, series.times.length - i0);
    if (n <= 0) return series;
    return {
      times: series.times.slice(i0, i0 + n),
      outdoor: series.outdoor.slice(i0, i0 + n),
      dewPoint: series.dewPoint.slice(i0, i0 + n),
      place: series.place,
      timeZone: series.timeZone,
      isDemo: series.isDemo,
    };
  }

  /** Série de démonstration : sinusoïde réaliste (min vers 5 h, max vers 17 h). */
  function demoSeries(nowMs) {
    if (nowMs === undefined) nowMs = Date.now();
    const timeZone = (Intl.DateTimeFormat().resolvedOptions().timeZone) || 'UTC';
    // Début d'heure LOCALE (les fuseaux en :30/:45 existent), comme Calendar.
    const d = new Date(nowMs);
    const anchor = nowMs - d.getMinutes() * 60000 - d.getSeconds() * 1000 - d.getMilliseconds();
    const times = [], temps = [];
    const fmt = hourFormatter(timeZone);
    for (let k = -1; k < 33; k++) {
      const t = anchor + k * 3600000;
      let h = 0;
      const parts = fmt.formatToParts(new Date(t));
      for (let i = 0; i < parts.length; i++) {
        if (parts[i].type === 'hour') h = parseInt(parts[i].value, 10) % 24;
      }
      times.push(t);
      temps.push(Math.round((26 - 8 * Math.cos(2 * Math.PI * (h - 5) / 24)) * 10) / 10);
    }
    return {
      times: times, outdoor: temps,
      dewPoint: times.map(function () { return 12; }),
      place: 'Exemple', timeZone: timeZone, isDemo: true,
    };
  }

  // --- Modèle thermique (ThermalModel.swift) -------------------------------

  /** Cloche en cos² : pic à `peak`, nulle au-delà de ±width heures. */
  function bell(hour, peak, width) {
    const x = Math.abs(hour - peak);
    if (!(x < width)) return 0;
    const c = Math.cos(Math.PI / 2 * x / width);
    return c * c;
  }

  /** Apport solaire à une heure donnée, selon l'exposition. */
  function solarGains(hour, exposure) {
    const dual = isDual(exposure);
    const perFace = dual ? 0.6 : 1.0;
    let gains = DIFFUSE_SOLAR * (dual ? 1.2 : 1) * bell(hour, 13.5, 7.5);
    const facades = facadesOf(exposure);
    for (let i = 0; i < facades.length; i++) {
      const info = FACADES[facades[i]];
      if (info.peak === null) continue;
      gains += DIRECT_SOLAR * perFace * bell(hour, info.peak, info.width);
    }
    return gains;
  }

  /** Simule la température intérieure sur la série météo donnée.
      Retourne { indoor: number[], isOpen: boolean[] }. */
  function simulate(series, indoorNow, inertia, ventilation, exposure) {
    const n = series.outdoor.length;
    if (n === 0) return { indoor: [], isOpen: [] };

    const dual = isDual(exposure);
    const crossMultiplier = dual ? (isCrossOpposite(exposure) ? 1.8 : 1.5) : 1.0;
    const envelope = ENVELOPE_LOSS * (dual ? 1.15 : 1);
    const massCapacity = WALL_KAPPA[inertia] * FLOOR_AREA;
    const ventilationConductance =
      AIR_HEAT_CAPACITY_PER_VOLUME * VENT_ACH[ventilation] * crossMultiplier * VOLUME / 3600;
    const dt = 3600.0 / SUBSTEPS;

    const initialGains = INTERNAL_GAINS
      + SHADE_FACTOR * solarGains(hourAt(series, 0), exposure);
    let airTemp = indoorNow;
    let massTemp = indoorNow
      - (envelope * (series.outdoor[0] - indoorNow) + initialGains) / AIR_MASS_COUPLING;

    let isOpen = false;
    const indoor = [airTemp];
    const open = [];

    for (let i = 0; i < n; i++) {
      const solar = solarGains(hourAt(series, i), exposure);
      const solarPenalty = (1 - SHADE_FACTOR) * solar / ventilationConductance;
      if (isOpen) {
        if (series.outdoor[i] > airTemp - CLOSE_THRESHOLD - solarPenalty) isOpen = false;
      } else {
        if (series.outdoor[i] < airTemp - OPEN_THRESHOLD - solarPenalty) isOpen = true;
      }
      open.push(isOpen);
      if (i === n - 1) break;

      const gains = INTERNAL_GAINS + (isOpen ? 1 : SHADE_FACTOR) * solar;
      const airOutdoorConductance = envelope + (isOpen ? ventilationConductance : 0);
      for (let s = 0; s < SUBSTEPS; s++) {
        const dAir = (dt / AIR_NODE_CAPACITY)
          * (airOutdoorConductance * (series.outdoor[i] - airTemp)
            + AIR_MASS_COUPLING * (massTemp - airTemp)
            + gains);
        const dMass = (dt / massCapacity) * (AIR_MASS_COUPLING * (airTemp - massTemp));
        airTemp += dAir;
        massTemp += dMass;
      }
      indoor.push(airTemp);
    }
    return { indoor: indoor, isOpen: open };
  }

  /** Gain au moment le plus chaud, pour une configuration donnée. */
  function peakDrop(series, indoorNow, inertia, ventilation, exposure, peakIndex) {
    const result = simulate(series, indoorNow, inertia, ventilation, exposure);
    if (peakIndex < 0 || peakIndex >= result.indoor.length) return 0;
    return Math.max(0, series.outdoor[peakIndex] - result.indoor[peakIndex]);
  }

  // --- Analyse (ThermalAnalysis.swift) -------------------------------------

  function pad2(x) { return (x < 10 ? '0' : '') + x; }

  /** Analyse complète : créneaux, repères du graphe, chiffres du verdict.
      `series` doit déjà être fenêtrée (windowSeries). */
  function analyze(series, indoorNow, inertia, ventilation, exposure) {
    const result = simulate(series, indoorNow, inertia, ventilation, exposure);

    const runs = [];
    let start = -1;
    for (let i = 0; i < result.isOpen.length; i++) {
      if (result.isOpen[i]) {
        if (start < 0) start = i;
      } else if (start >= 0) {
        runs.push([start, i - 1]);
        start = -1;
      }
    }
    if (start >= 0) runs.push([start, result.isOpen.length - 1]);

    const outdoor = series.outdoor;
    let coolestIndex = 0;
    for (let i = 1; i < outdoor.length; i++) {
      if (outdoor[i] < outdoor[coolestIndex]) coolestIndex = i;
    }

    const firstOpen = runs.length ? runs[0][0] : 0;
    let peakIndex = firstOpen;
    for (let i = firstOpen; i < outdoor.length; i++) {
      // >= : à égalité, garder le dernier maximum, comme Sequence.max(by:).
      if (outdoor[i] >= outdoor[peakIndex]) peakIndex = i;
    }

    const indoor = result.indoor;
    let indoorMinIndex = 0;
    for (let i = 1; i < indoor.length; i++) {
      if (indoor[i] < indoor[indoorMinIndex]) indoorMinIndex = i;
    }

    function drop(inertiaOption, ventilationOption) {
      return peakDrop(series, indoorNow, inertiaOption, ventilationOption, exposure, peakIndex);
    }
    const total = Math.max(0, outdoor[peakIndex] - indoor[peakIndex]);
    const base = drop('light', 'low');
    const walls = Math.max(0, drop(inertia, 'low') - base);
    const vent = Math.max(0, drop('light', ventilation) - base);
    const synergy = Math.max(0, total - base - walls - vent);
    const breakdown = {
      base: base, walls: walls, ventilation: vent, synergy: synergy, total: total,
      showsSynergy: synergy >= 0.15,
    };

    // Air humide pendant les heures d'ouverture conseillées.
    let dewSum = 0, dewCount = 0;
    for (let i = 0; i < result.isOpen.length; i++) {
      if (result.isOpen[i]) { dewSum += series.dewPoint[i]; dewCount++; }
    }
    const humidDuringOpenings = dewCount > 0 && dewSum / dewCount > 16;

    function endLabel(run) {
      return pad2((hourAt(series, run[1]) + 1) % 24) + 'h';
    }
    function rangeLabel(run) {
      return 'de ' + hourLabel(series, run[0]) + ' à ' + endLabel(run);
    }

    const shouldOpenNow = result.isOpen.length ? result.isOpen[0] : false;
    let verdictTitle;
    if (!runs.length) {
      verdictTitle = 'Gardez fermé';
    } else {
      verdictTitle = shouldOpenNow
        ? "Ouvrez jusqu'à " + endLabel(runs[0])
        : 'Ouvrez ' + rangeLabel(runs[0]);
    }

    return {
      series: series,
      indoorNow: indoorNow,
      result: result,
      runs: runs,
      coolestIndex: coolestIndex,
      peakIndex: peakIndex,
      indoorMinIndex: indoorMinIndex,
      breakdown: breakdown,
      shouldOpenNow: shouldOpenNow,
      coolerAtPeak: Math.max(0, outdoor[peakIndex] - indoor[peakIndex]),
      indoorMin: indoor.length ? indoor[indoorMinIndex] : indoorNow,
      humidDuringOpenings: humidDuringOpenings,
      verdictTitle: verdictTitle,
      secondWindowLabel: runs.length > 1 ? rangeLabel(runs[1]) : null,
      firstWindow: runs.length
        ? { start: series.times[runs[0][0]], end: series.times[runs[0][1]] + 3600000 }
        : null,
      endLabel: endLabel,
      rangeLabel: rangeLabel,
    };
  }

  // --- Formats (Theme.swift) -----------------------------------------------

  /** Une décimale, virgule française : 4.7 → « 4,7 ». */
  function oneDecimal(x) { return x.toFixed(1).replace('.', ','); }
  /** Entier arrondi : 26.0 → « 26 ». */
  function noDecimal(x) { return String(Math.round(x)); }

  // --- Export ---------------------------------------------------------------

  const NadirEngine = {
    FLOOR_AREA: FLOOR_AREA, VOLUME: VOLUME,
    AIR_NODE_CAPACITY: AIR_NODE_CAPACITY, AIR_MASS_COUPLING: AIR_MASS_COUPLING,
    ENVELOPE_LOSS: ENVELOPE_LOSS, INTERNAL_GAINS: INTERNAL_GAINS,
    DIRECT_SOLAR: DIRECT_SOLAR, DIFFUSE_SOLAR: DIFFUSE_SOLAR,
    SHADE_FACTOR: SHADE_FACTOR, SUBSTEPS: SUBSTEPS,
    OPEN_THRESHOLD: OPEN_THRESHOLD, CLOSE_THRESHOLD: CLOSE_THRESHOLD,
    WALL_KAPPA: WALL_KAPPA, WALL_LABEL: WALL_LABEL,
    VENT_ACH: VENT_ACH, VENT_LABEL: VENT_LABEL,
    FACADES: FACADES, FACADE_ORDER: FACADE_ORDER, OPPOSITE: OPPOSITE,
    isDual: isDual, facadesOf: facadesOf, isCrossOpposite: isCrossOpposite,
    exposureContains: exposureContains, exposureLabel: exposureLabel,
    toggleExposure: toggleExposure,
    hourAt: hourAt, hourLabel: hourLabel,
    windowSeries: windowSeries, demoSeries: demoSeries,
    bell: bell, solarGains: solarGains,
    simulate: simulate, peakDrop: peakDrop, analyze: analyze,
    oneDecimal: oneDecimal, noDecimal: noDecimal,
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = NadirEngine;
  if (typeof window !== 'undefined') window.NadirEngine = NadirEngine;
})();
