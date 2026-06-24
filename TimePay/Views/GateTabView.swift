import SwiftUI

struct GateTabView: View {
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var settings: AppSettings
    @State private var showSetup = false
    @State private var showAddApp = false
    @State private var customAppName = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerHero

                if !gate.setupCompleted {
                    setupBanner
                }

                categoryChips

                HStack {
                    Text("\(gate.filteredApps.count) Apps")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.45))
                    Spacer()
                    GlassPill(
                        text: "\(gate.enabledApps.count) geschützt",
                        color: gate.enabledApps.isEmpty ? .orange : NOCOTheme.mint
                    )
                    Button {
                        showAddApp = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(NOCOTheme.teal)
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(gate.filteredApps) { app in
                        GlassAppTile(app: app) {
                            settings.impact(.light)
                            withAnimation(.spring(response: 0.35)) {
                                gate.toggleApp(app.id)
                            }
                        }
                        .contextMenu {
                            if app.isCustom {
                                Button(role: .destructive) {
                                    gate.removeCustomApp(app.id)
                                } label: {
                                    Label("Entfernen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                if gate.filteredApps.isEmpty {
                    GlassCard(glow: .orange, padding: 16) {
                        Text("Keine Apps gefunden — Suche anpassen oder eigene App hinzufügen.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .searchable(text: $gate.searchQuery, prompt: "App suchen…")
        .sheet(isPresented: $showSetup) {
            OneTapSetupView()
        }
        .sheet(isPresented: $showAddApp) {
            addAppSheet
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
                    Text("Liquid Glass Gate — Kurzbefehl statt Fokus")
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
        Button {
            showSetup = true
        } label: {
            GlassCard(glow: NOCOTheme.lavender, padding: 14) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .foregroundStyle(NOCOTheme.lavender)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ein-Tap Setup")
                            .font(.subheadline.weight(.bold))
                        Text("Kurzbefehl importieren → bestätigen → fertig")
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

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "Alle", icon: "square.grid.2x2", isSelected: gate.selectedCategory == nil) {
                    withAnimation(.spring(response: 0.3)) { gate.selectedCategory = nil }
                }
                ForEach(AppCategory.allCases) { category in
                    CategoryChip(
                        title: category.title,
                        icon: category.icon,
                        isSelected: gate.selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            gate.selectedCategory = gate.selectedCategory == category ? nil : category
                        }
                    }
                }
            }
        }
    }

    private var addAppSheet: some View {
        NavigationStack {
            ZStack {
                NOCOTheme.midnight.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Eigene App hinzufügen")
                        .font(.title3.bold())
                    Text("Name wie in Kurzbefehle-Automation verwenden.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                    TextField("App-Name", text: $customAppName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    Button {
                        gate.addCustomApp(name: customAppName)
                        customAppName = ""
                        settings.success()
                        showAddApp = false
                    } label: {
                        Text("Hinzufügen")
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
