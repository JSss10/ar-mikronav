// NotificationSettings.swift
// ARMikronav
//
// Benachrichtigungs-Einstellungen (Wireframe 4.5): Push- und Annäherungs-
// Toggles, Ton, Vibration, Warn-Radius und der Opt-in für neue Barrieren-
// Daten im Testgebiet. Persistiert vom NotificationSettingsStore.
// decodeIfPresent hält alte gespeicherte Versionen kompatibel.

import Foundation

struct NotificationSettings: Codable, Equatable {
    var warningRadius: Double
    var warningsEnabled: Bool
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    var newDataAlerts: Bool

    static let `default` = NotificationSettings(
        warningRadius: AppConfig.approachWarningDistance,
        warningsEnabled: true,
        soundEnabled: false,
        vibrationEnabled: true,
        newDataAlerts: false
    )

    static let minRadius: Double = 15
    static let maxRadius: Double = 100
    static let radiusStep: Double = 5

    init(
        warningRadius: Double,
        warningsEnabled: Bool,
        soundEnabled: Bool,
        vibrationEnabled: Bool,
        newDataAlerts: Bool
    ) {
        self.warningRadius = warningRadius
        self.warningsEnabled = warningsEnabled
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        self.newDataAlerts = newDataAlerts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        warningRadius = try container.decodeIfPresent(Double.self, forKey: .warningRadius) ?? 30
        warningsEnabled = try container.decodeIfPresent(Bool.self, forKey: .warningsEnabled) ?? true
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? false
        vibrationEnabled = try container.decodeIfPresent(Bool.self, forKey: .vibrationEnabled) ?? true
        newDataAlerts = try container.decodeIfPresent(Bool.self, forKey: .newDataAlerts) ?? false
    }
}
