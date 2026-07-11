import HomeKit
import Observation

/// Capteurs de température HomeKit : sondes HomeKit ou Matter, et tout
/// capteur exposé par un pont (Home Assistant…). Découvre les capteurs
/// disponibles, puis lit et suit celui que l'utilisateur a choisi.
/// Les HomePod ne sont pas accessibles : Apple ne les expose pas aux apps.
@MainActor
@Observable
final class HomeKitService: NSObject {
    struct Sensor: Identifiable, Equatable {
        /// Identifiant du service HomeKit, stable entre les lancements.
        let id: UUID
        /// « Sonde · Salon »
        let name: String
    }

    /// Capteurs de température visibles dans les maisons de l'utilisateur.
    private(set) var sensors: [Sensor] = []
    /// Vrai une fois les maisons réellement livrées par HomeKit : avant,
    /// une liste vide veut juste dire « chargement en cours ».
    private(set) var isLoaded = false
    /// Accès HomeKit refusé dans Réglages, ou restreint par le système.
    private(set) var isDenied = false
    /// Reçoit chaque mesure du capteur suivi (identifiant, °C).
    var onReading: ((UUID, Double) -> Void)?

    private var manager: HMHomeManager?
    private var monitoredID: UUID?
    private var monitoredCharacteristic: HMCharacteristic?
    /// Les notifications couvrent le premier plan : la relecture à la
    /// demande est donc espacée pour ménager les capteurs sur pile.
    private var lastReadAt: Date?
    private static let readInterval: TimeInterval = 300

    /// Créer le gestionnaire déclenche la demande d'autorisation HomeKit :
    /// on ne le fait donc qu'à la demande, jamais au simple lancement.
    func start() {
        guard manager == nil else {
            refresh()
            return
        }
        let manager = HMHomeManager()
        manager.delegate = self
        self.manager = manager
    }

    /// Vrai quand le capteur suivi est réellement branché : il a disparu
    /// de la maison si c'est faux alors qu'un capteur est lié.
    var isMonitorAttached: Bool {
        monitoredCharacteristic != nil
    }

    /// Suit un capteur : lecture immédiate puis notifications de changement.
    func monitor(sensorID: UUID) {
        guard monitoredID != sensorID else {
            // Re-lier le même capteur vaut demande de lecture immédiate.
            readNow(force: true)
            return
        }
        detachMonitor()
        monitoredID = sensorID
        start()
        attachMonitor()
    }

    func stopMonitoring() {
        detachMonitor()
        monitoredID = nil
    }

    /// Relit le capteur suivi, au retour de l'app au premier plan.
    /// Espacée sauf `force`, car aussi appelée par le tic d'horloge de l'app.
    func readNow(force: Bool = false) {
        guard let characteristic = monitoredCharacteristic else { return }
        if !force, let lastReadAt, Date.now.timeIntervalSince(lastReadAt) < Self.readInterval {
            return
        }
        lastReadAt = .now
        characteristic.readValue { [weak self] error in
            guard error == nil else { return }
            Task { @MainActor in
                self?.deliver(from: characteristic)
            }
        }
    }

    // MARK: - Privé

    /// `homesDelivered` : vrai seulement depuis homeManagerDidUpdateHomes,
    /// le seul moment où HomeKit garantit que la liste des maisons est à jour.
    private func refresh(homesDelivered: Bool = false) {
        guard let manager else { return }
        let status = manager.authorizationStatus
        isDenied = status.contains(.restricted)
            || (status.contains(.determined) && !status.contains(.authorized))
        var found: [Sensor] = []
        for home in manager.homes {
            home.delegate = self
            for accessory in home.accessories {
                for service in accessory.services
                where service.serviceType == HMServiceTypeTemperatureSensor {
                    guard Self.temperatureCharacteristic(of: service) != nil else { continue }
                    found.append(Sensor(id: service.uniqueIdentifier, name: Self.displayName(accessory, service)))
                }
            }
        }
        sensors = found.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        if homesDelivered { isLoaded = true }
        attachMonitor()
    }

    /// Branche lecture et notifications sur le capteur suivi, s'il est visible.
    private func attachMonitor() {
        guard let monitoredID,
              monitoredCharacteristic?.service?.uniqueIdentifier != monitoredID,
              let manager else { return }
        for home in manager.homes {
            for accessory in home.accessories {
                for service in accessory.services where service.uniqueIdentifier == monitoredID {
                    guard let characteristic = Self.temperatureCharacteristic(of: service) else { continue }
                    monitoredCharacteristic = characteristic
                    accessory.delegate = self
                    armNotifications()
                    readNow(force: true)
                    return
                }
            }
        }
    }

    /// À rejouer après chaque retour de joignabilité : HomeKit désarme
    /// les notifications d'un accessoire devenu injoignable.
    private func armNotifications() {
        guard let characteristic = monitoredCharacteristic,
              characteristic.properties.contains(HMCharacteristicPropertySupportsEventNotification)
        else { return }
        characteristic.enableNotification(true) { _ in }
    }

    private func detachMonitor() {
        if let characteristic = monitoredCharacteristic {
            if characteristic.properties.contains(HMCharacteristicPropertySupportsEventNotification) {
                characteristic.enableNotification(false) { _ in }
            }
            // Sans quoi l'ancien capteur continuerait de nous parler.
            characteristic.service?.accessory?.delegate = nil
        }
        monitoredCharacteristic = nil
    }

    /// Les objets HomeKit en main sont périmés (maison rechargée, accessoire
    /// retiré…) : on oublie la référence et on se rattache sur les frais.
    private func invalidateAndReattach(homesDelivered: Bool = false) {
        monitoredCharacteristic = nil
        refresh(homesDelivered: homesDelivered)
    }

    private func deliver(from characteristic: HMCharacteristic) {
        // Le même service porte aussi des états numériques (pile faible,
        // défaut…) : seule la température doit passer.
        guard let monitoredID,
              characteristic.characteristicType == HMCharacteristicTypeCurrentTemperature,
              characteristic.service?.uniqueIdentifier == monitoredID,
              let value = (characteristic.value as? NSNumber)?.doubleValue else { return }
        onReading?(monitoredID, value)
    }

    private static func temperatureCharacteristic(of service: HMService) -> HMCharacteristic? {
        service.characteristics.first { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }
    }

    private static func displayName(_ accessory: HMAccessory, _ service: HMService) -> String {
        guard let room = accessory.room?.name, !accessory.name.localizedCaseInsensitiveContains(room) else {
            return accessory.name
        }
        return "\(accessory.name) · \(room)"
    }
}

// HomeKit livre ses rappels sur le fil principal : on l'atteste au compilateur.
extension HomeKitService: HMHomeManagerDelegate {
    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        MainActor.assumeIsolated { invalidateAndReattach(homesDelivered: true) }
    }

    nonisolated func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        MainActor.assumeIsolated { refresh() }
    }
}

extension HomeKitService: HMHomeDelegate {
    nonisolated func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        MainActor.assumeIsolated { refresh() }
    }

    nonisolated func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        MainActor.assumeIsolated { invalidateAndReattach() }
    }
}

extension HomeKitService: HMAccessoryDelegate {
    nonisolated func accessory(
        _ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic
    ) {
        MainActor.assumeIsolated { deliver(from: characteristic) }
    }

    nonisolated func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        MainActor.assumeIsolated {
            guard accessory.isReachable,
                  let monitoredID,
                  accessory.services.contains(where: { $0.uniqueIdentifier == monitoredID })
            else { return }
            armNotifications()
            readNow(force: true)
        }
    }
}
