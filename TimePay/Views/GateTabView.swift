import SwiftUI

struct GateTabView: View {
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var settings: AppSettings
    @State private var showSetup = false
    @State private var showAddApp = false
    @State private var customAppName = ""
    @State private var listMode = true

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerHero
                    if !gate.setupCompleted { setupBanner }
                    quickPresets
                    if !gate.enabledApps.isEmpty { enabledSummary }
                    searchAndModeBar
                    appList
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, TabBarMetrics.contentBottomInset)
            }
            .navigationTitle("Apps")
            .appleGlassNavigation()
            .searchable(text: $gate.searchQuery, prompt: "App suchen…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddApp = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(NOCOTheme.teal)
                    }
                }
            }
            .sheet(isPresented: $showSetup) { OneTapSetupView() }
            .sheet(isPresented: $showAddApp) { addAppSheet }
        }
    }

    private var quickPresets: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Schnellauswahl")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.45))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AppSelectionPreset.allCases) { preset in
                        Button {
                            settings.impact(.medium)
                            withAnimation(.spring(response: 0.35)) {
                                gate.applySelectionPreset(preset)
                            }
                        } label: {
                            Label(preset.title, systemImage: preset.icon)
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(NOCOTheme.teal.opacity(0.14), in: Capsule())
                                .foregroundStyle(NOCOTheme.teal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var enabledSummary: some View {
        GlassCard(glow: NOCOTheme.mint, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(gate.enabledApps.count) Apps geschützt")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Button("Alle aus") {
                        gate.disableAllApps()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                }
                FlowLayout(spacing: 8) {
                    ForEach(gate.enabledApps) { app in
                        Button {
                            gate.toggleApp(app.id)
                        } label: {
                            GlassPill(text: app.name, color: app.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var searchAndModeBar: some View {
        HStack {
            Text("\(gate.filteredApps.count) Apps")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Picker("Ansicht", selection: $listMode) {
                Image(systemName: "list.bullet").tag(true)
                Image(systemName: "square.grid.3x3").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            Button { showAddApp = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(NOCOTheme.teal)
            }
        }
    }

    @ViewBuilder
    private var appList: some View {
        if listMode {
            VStack(spacing: 8) {
                ForEach(gate.filteredApps) { app in
                    appListRow(app)
                }
            }
        } else {
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(gate.filteredApps) { app in
                    GlassAppTile(app: app) {
                        settings.impact(.light)
                        withAnimation(.spring(response: 0.35)) { gate.toggleApp(app.id) }
                    }
                }
            }
        }

        if gate.filteredApps.isEmpty {
            GlassCard(glow: .orange, padding: 16) {
                Text("Keine Apps gefunden — Suche anpassen oder + tippen.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func appListRow(_ app: ProtectedApp) -> some View {
        GlassCard(padding: 12) {
            HStack(spacing: 14) {
                Image(systemName: app.symbol)
                    .font(.title3)
                    .foregroundStyle(app.accent)
                    .frame(width: 40, height: 40)
                    .background(app.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.subheadline.weight(.semibold))
                    Text(app.category.title)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { gate.protectedApps.first(where: { $0.id == app.id })?.isEnabled ?? false },
                    set: { _ in
                        settings.impact(.light)
                        gate.toggleApp(app.id)
                    }
                ))
                .labelsHidden()
                .tint(NOCOTheme.teal)
            }
        }
        .contextMenu {
            if app.isCustom {
                Button(role: .destructive) { gate.removeCustomApp(app.id) } label: {
                    Label("Entfernen", systemImage: "trash")
                }
            }
        }
    }

    private var headerHero: some View {
        GlassCard(glow: ShortcutGateManager.isGateOpen ? NOCOTheme.teal : .orange, padding: 18) {
            HStack(spacing: 16) {
                GateOrbView(
                    isOpen: ShortcutGateManager.isGateOpen,
                    progress: store.unlockSessionRemaining > 0 ? store.unlockProgress : 0,
                    size: 88
                )
                VStack(alignment: .leading, spacing: 8) {
                    Text("Geschützte Apps")
                        .font(.headline.weight(.bold))
                    Text("Tippe Schnellauswahl oder schalte Apps einzeln")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    StatusBadge(
                        text: gate.gateStatusLabel,
                        color: ShortcutGateManager.isGateOpen ? NOCOTheme.teal : .orange,
                        icon: ShortcutGateManager.isGateOpen ? "lock.open.fill" : "lock.fill"
                    )
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var setupBanner: some View {
        Button { showSetup = true } label: {
            GlassCard(glow: NOCOTheme.lavender, padding: 14) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .foregroundStyle(NOCOTheme.lavender)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Setup abschließen")
                            .font(.subheadline.weight(.bold))
                        Text("3 Schritte — Kurzbefehl importieren & Automation")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var addAppSheet: some View {
        NavigationStack {
            ZStack {
                NOCOTheme.midnight.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Eigene App")
                        .font(.title3.bold())
                    Text("Name wie in Kurzbefehle-Automation (z. B. „Disney+“).")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    TextField("App-Name", text: $customAppName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    Button {
                        gate.addCustomApp(name: customAppName)
                        customAppName = ""
                        settings.success()
                        showAddApp = false
                    } label: {
                        Text("Hinzufügen & schützen")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NOCOPrimaryButtonStyle(enabled: !customAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                    .padding(.horizontal)
                    Spacer()
                }
                .padding(.top, 24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { showAddApp = false }
                        .foregroundStyle(NOCOTheme.teal)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
