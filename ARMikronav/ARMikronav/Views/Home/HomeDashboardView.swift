// HomeDashboardView.swift
// ARMikronav
//
// Homescreen (Start-Tab): begrüsst den User mit Name und Profilfoto, zeigt
// das aktuelle Wetter am Standort (Open-Meteo, inkl. UV-Index), die letzten
// Navigationsziele und die neuesten Barrieren-Meldungen aus der ganzen
// Zürcher Altstadt. Karten-Interaktionen (Ziel ansteuern, Barriere ansehen)
// laufen über den onOpenMap-Callback des HomeView.

import SwiftUI
import CoreLocation

struct HomeDashboardView: View {
    /// Wechselt zum Karten-Tab (z. B. Tap auf ein Ziel oder eine Barriere).
    let onOpenMap: () -> Void

    @StateObject private var viewModel = HomeDashboardViewModel()
    @StateObject private var recentDestinations = RecentDestinationsStore.shared
    @StateObject private var avatarStore = AvatarStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.Space.l) {
                header
                weatherCard
                recentDestinationsSection
                newBarriersSection
            }
            .padding(.horizontal, AppMetrics.Space.m)
            .padding(.top, AppMetrics.Space.m)
            .padding(.bottom, AppMetrics.Space.xl)
        }
        .background(AppColor.backgroundPrimary)
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            viewModel.start()
            avatarStore.loadIfNeeded()
        }
    }

    // MARK: - Begrüssung

    private var header: some View {
        HStack(spacing: AppMetrics.Space.m) {
            avatar

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColor.textPrimary)
                Text(Date().formatted(.dateTime.locale(.appGerman).weekday(.wide).day().month(.wide)))
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.greeting) Heute ist \(Date().formatted(.dateTime.locale(.appGerman).weekday(.wide).day().month(.wide)))")
    }

    /// Profilbild (in den Einstellungen erfasst), sonst Initialen-Monogramm.
    private var avatar: some View {
        ZStack {
            if let photo = avatarStore.image {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(AppColor.accentPrimary)
                if viewModel.initials.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundStyle(AppColor.onAccent)
                } else {
                    Text(viewModel.initials)
                        .font(.headline)
                        .foregroundStyle(AppColor.onAccent)
                }
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    // MARK: - Wetter

    @ViewBuilder
    private var weatherCard: some View {
        heroCard {
            if let weather = viewModel.weather {
                VStack(spacing: AppMetrics.Space.m) {
                    HStack(spacing: AppMetrics.Space.m) {
                        Image(systemName: weather.symbolName)
                            .font(.system(size: 40))
                            .symbolRenderingMode(.multicolor)
                            .frame(width: 56)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(weather.temperatureC.rounded())) °C")
                                .font(AppTypography.title1)
                                .foregroundStyle(AppColor.textPrimary)
                            Text(weather.conditionDescription)
                                .font(AppTypography.subheadline)
                                .foregroundStyle(AppColor.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if let place = viewModel.weatherPlaceName {
                                Label(place, systemImage: "location.fill")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            Label("\(Int(weather.windSpeedKmh.rounded())) km/h", systemImage: "wind")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }

                    Divider()
                        .overlay(AppColor.borderDecorative)

                    HStack(spacing: AppMetrics.Space.s) {
                        weatherStat(
                            symbol: "sun.max.trianglebadge.exclamationmark",
                            label: "UV-Index",
                            value: String(format: "%.0f · %@", weather.uvIndex.rounded(), weather.uvCategory)
                        )
                        weatherStat(
                            symbol: "thermometer.medium",
                            label: "Gefühlt",
                            value: "\(Int(weather.feelsLikeC.rounded())) °C"
                        )
                        weatherStat(
                            symbol: "humidity.fill",
                            label: "Luftfeuchte",
                            value: "\(weather.humidityPercent) %"
                        )
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(weatherAccessibilityText(weather))
            } else if viewModel.isLoadingWeather {
                HStack(spacing: AppMetrics.Space.m) {
                    ProgressView()
                    Text("Wetter wird geladen…")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
            } else {
                HStack(alignment: .top, spacing: AppMetrics.Space.m) {
                    Image(systemName: "cloud.slash")
                        .font(.title2)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(viewModel.weatherError ?? "Wetter derzeit nicht verfügbar.")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Erneut") {
                        Task { await viewModel.loadWeather() }
                    }
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.accentPrimary)
                }
            }
        }
    }

    /// Mini-Statistik in der Wetterkarte (UV-Index, gefühlte Temperatur, …).
    private func weatherStat(symbol: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.accentPrimary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func weatherAccessibilityText(_ weather: CurrentWeather) -> String {
        var text = "Aktuelles Wetter"
        if let place = viewModel.weatherPlaceName {
            text += " in \(place)"
        }
        text += ": \(Int(weather.temperatureC.rounded())) Grad, \(weather.conditionDescription),"
        text += " gefühlt \(Int(weather.feelsLikeC.rounded())) Grad,"
        text += " Wind \(Int(weather.windSpeedKmh.rounded())) Kilometer pro Stunde,"
        text += " UV-Index \(Int(weather.uvIndex.rounded())) (\(weather.uvCategory)),"
        text += " Luftfeuchtigkeit \(weather.humidityPercent) Prozent"
        return text
    }

    // MARK: - Letzte Ziele

    private var recentDestinationsSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.Space.s) {
            sectionTitle("Letzte Ziele")

            if recentDestinations.destinations.isEmpty {
                card {
                    HStack(spacing: AppMetrics.Space.m) {
                        Image(systemName: "mappin.slash")
                            .font(.title2)
                            .foregroundStyle(AppColor.textSecondary)
                        Text("Noch keine Ziele – starte eine Navigation auf der Karte.")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                        Spacer()
                    }
                }
            } else {
                card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(recentDestinations.destinations.prefix(5)) { destination in
                            Button {
                                onOpenMap()
                            } label: {
                                destinationRow(destination)
                            }
                            .buttonStyle(.plain)

                            if destination.id != recentDestinations.destinations.prefix(5).last?.id {
                                Divider()
                                    .overlay(AppColor.borderDecorative)
                                    .padding(.leading, 52)
                            }
                        }
                    }
                }
            }
        }
    }

    private func destinationRow(_ destination: RecentDestination) -> some View {
        HStack(spacing: AppMetrics.Space.m) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(AppColor.accentPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text(destinationSubtitle(destination))
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, AppMetrics.Space.m)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(destination.name), \(destinationSubtitle(destination)), öffnet die Karte")
        .accessibilityAddTraits(.isButton)
    }

    private func destinationSubtitle(_ destination: RecentDestination) -> String {
        var parts = [destination.visitedAt.formatted(.relative(presentation: .named).locale(.appGerman))]
        if let distance = viewModel.distanceText(
            latitude: destination.latitude,
            longitude: destination.longitude
        ) {
            parts.append(distance)
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Neue Barrieren

    private var newBarriersSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.Space.s) {
            sectionTitle("Neue Barrieren")

            if viewModel.isLoadingBarriers && viewModel.newBarriers.isEmpty {
                card {
                    HStack(spacing: AppMetrics.Space.m) {
                        ProgressView()
                        Text("Meldungen werden geladen…")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            } else if let error = viewModel.barriersError {
                card {
                    HStack(spacing: AppMetrics.Space.m) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(AppColor.textSecondary)
                        Text(error)
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                        Spacer()
                        Button("Erneut") {
                            Task { await viewModel.loadBarriers() }
                        }
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.accentPrimary)
                    }
                }
            } else if viewModel.newBarriers.isEmpty {
                card {
                    HStack(spacing: AppMetrics.Space.m) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(AppColor.Status.openIcon)
                        Text("Keine neuen Barrieren-Meldungen in der Altstadt.")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                        Spacer()
                    }
                }
            } else {
                card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.newBarriers) { barrier in
                            Button {
                                onOpenMap()
                            } label: {
                                barrierRow(barrier)
                            }
                            .buttonStyle(.plain)

                            if barrier.id != viewModel.newBarriers.last?.id {
                                Divider()
                                    .overlay(AppColor.borderDecorative)
                                    .padding(.leading, 68)
                            }
                        }
                    }
                }
            }
        }
    }

    private func barrierRow(_ barrier: Barrier) -> some View {
        HStack(spacing: AppMetrics.Space.m) {
            ZStack {
                Circle()
                    .fill(barrier.type.tint)
                    .frame(width: 40, height: 40)
                Image(systemName: barrier.type.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppMetrics.Space.s) {
                    Text(barrier.type.localizedLabel)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.textPrimary)
                    if isNew(barrier) {
                        Text("Neu")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColor.Status.limitedFill, in: Capsule())
                            .foregroundStyle(AppColor.Status.limitedText)
                    }
                }
                if let subtitle = barrierSubtitle(barrier) {
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, AppMetrics.Space.m)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(barrierAccessibilityText(barrier))
        .accessibilityAddTraits(.isButton)
    }

    /// Gemeldet innerhalb der letzten 7 Tage → "Neu"-Badge.
    private func isNew(_ barrier: Barrier) -> Bool {
        guard let verified = barrier.lastVerified else { return false }
        return Date().timeIntervalSince(verified) < HomeDashboardViewModel.newBadgeInterval
    }

    /// Messwert, Distanz und Meldedatum der Barriere als eine Zeile.
    private func barrierSubtitle(_ barrier: Barrier) -> String? {
        var parts: [String] = []
        switch barrier.type {
        case .steps:
            if let v = barrier.value { parts.append("\(Int(v)) Stufen") }
        case .curb, .curbMissing:
            if let v = barrier.value { parts.append("\(Int(v)) cm hoch") }
        case .incline:
            if let v = barrier.value { parts.append("\(Int(v)) % Steigung") }
        case .narrow:
            if let v = barrier.value { parts.append("\(Int(v)) cm Durchgang") }
        case .surface:
            if let s = barrier.subtype {
                parts.append(s.replacingOccurrences(of: "_", with: " ").capitalized)
            }
        case .temporary:
            break
        }
        if let distance = viewModel.distanceText(
            latitude: barrier.latitude,
            longitude: barrier.longitude
        ) {
            parts.append(distance)
        }
        if let verified = barrier.lastVerified {
            parts.append("gemeldet " + verified.formatted(.relative(presentation: .named).locale(.appGerman)))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func barrierAccessibilityText(_ barrier: Barrier) -> String {
        var parts = [barrier.type.localizedLabel]
        if isNew(barrier) { parts.append("neue Meldung") }
        if let subtitle = barrierSubtitle(barrier) { parts.append(subtitle) }
        parts.append("öffnet die Karte")
        return parts.joined(separator: ", ")
    }

    // MARK: - Bausteine

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.title2)
            .foregroundStyle(AppColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private func card<Content: View>(
        padding: CGFloat = AppMetrics.Space.m,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppColor.surfaceRaised,
                in: RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous)
                    .stroke(AppColor.borderDecorative, lineWidth: 1)
            )
    }

    /// Hervorgehobene Karte (Wetter) mit sanftem Akzent-Verlauf – gibt dem
    /// Homescreen einen freundlichen, modernen Auftakt, ohne die Lesbarkeit
    /// der Werte zu beeinträchtigen.
    private func heroCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(AppMetrics.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [AppColor.Violet.v100, AppColor.surfaceRaised],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous)
                    .stroke(AppColor.borderDecorative, lineWidth: 1)
            )
    }
}