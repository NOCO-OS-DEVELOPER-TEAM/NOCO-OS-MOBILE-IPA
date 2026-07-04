import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var step = 0
    @State private var focusGoal = OnboardingProfile.focusOptions[1]
    @State private var budgetTracking = false
    @State private var wantsGoal = false
    @State private var goalName = ""
    @State private var goalAmountText = ""

    private let totalSteps = 4

    var body: some View {
        ZStack {
            LiveCashTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: focusStep
                    case 2: goalStep
                    default: assistantStep
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: step)

                footerButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .interactiveDismissDisabled()
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Live Cash")
                    .font(LiveCashTheme.headlineFont)
                Spacer()
                Text("Schritt \(step + 1)/\(totalSteps)")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(step + 1), total: Double(totalSteps))
                .tint(LiveCashTheme.accent)
        }
    }

    private var welcomeStep: some View {
        onboardingCard(
            icon: "eurosign.circle.fill",
            title: "Willkommen bei Live Cash",
            subtitle: "Dein persönliches Finanz-System — lokal, privat, unter deiner Kontrolle. In 30 Sekunden bist du startklar."
        )
    }

    private var focusStep: some View {
        VStack(spacing: 20) {
            onboardingCard(
                icon: "target",
                title: "Was ist dein Ziel?",
                subtitle: "Live Cash passt sich an dein Verhalten an — je mehr du nutzt, desto smarter wird es."
            )
            VStack(spacing: 10) {
                ForEach(OnboardingProfile.focusOptions, id: \.self) { option in
                    Button {
                        focusGoal = option
                        HapticService.selection(store: store)
                    } label: {
                        HStack {
                            Text(option)
                                .font(LiveCashTheme.bodyFont.weight(.medium))
                            Spacer()
                            if focusGoal == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(LiveCashTheme.accent)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(focusGoal == option ? LiveCashTheme.accent : LiveCashTheme.glassBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Toggle("Ausgabenlimits aktivieren", isOn: $budgetTracking)
                .font(LiveCashTheme.bodyFont)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 24)
    }

    private var goalStep: some View {
        VStack(spacing: 20) {
            onboardingCard(
                icon: "banknote.fill",
                title: "Sparziel (optional)",
                subtitle: "Du kannst jederzeit später ein Ziel anlegen."
            )
            Toggle("Sparziel jetzt anlegen", isOn: $wantsGoal)
                .font(LiveCashTheme.bodyFont)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if wantsGoal {
                VStack(spacing: 12) {
                    TextField("Name, z. B. Urlaub", text: $goalName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Zielbetrag in €", text: $goalAmountText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 24)
    }

    private var assistantStep: some View {
        VStack(spacing: 20) {
            onboardingCard(
                icon: "sparkles",
                title: "Smart Assistant",
                subtitle: "Gib Ausgaben und Einnahmen einfach ein — z. B. „12€ Kaffee“ oder „Gehalt 2500“. Die App erkennt Betrag, Kategorie und Sparziele automatisch."
            )
            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "minus.circle.fill", text: "Ausgabe eingeben", color: LiveCashTheme.expense)
                tipRow(icon: "plus.circle.fill", text: "Einnahme eingeben", color: LiveCashTheme.income)
                tipRow(icon: "target", text: "Sparziele werden automatisch erkannt", color: LiveCashTheme.accent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 24)
    }

    private func onboardingCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(LiveCashTheme.accent)
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(LiveCashTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(LiveCashTheme.bodyFont)
        }
    }

    private var footerButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Zurück") {
                    withAnimation { step -= 1 }
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            Button(step == totalSteps - 1 ? "Los geht's" : "Weiter") {
                if step == totalSteps - 1 {
                    finish()
                } else {
                    withAnimation { step += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(step == 2 && wantsGoal && !canSaveGoal)
        }
    }

    private var canSaveGoal: Bool {
        guard wantsGoal else { return true }
        let name = goalName.trimmingCharacters(in: .whitespaces)
        let amount = Double(goalAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        return !name.isEmpty && amount > 0
    }

    private func finish() {
        let profile = OnboardingProfile(focusGoal: focusGoal, budgetTrackingEnabled: budgetTracking)
        var goalNameValue: String?
        var goalAmount: Double?
        if wantsGoal {
            let name = goalName.trimmingCharacters(in: .whitespaces)
            if let amount = Double(goalAmountText.replacingOccurrences(of: ",", with: ".")), amount > 0, !name.isEmpty {
                goalNameValue = name
                goalAmount = amount
            }
        }
        store.completeOnboarding(profile: profile, goalName: goalNameValue, goalAmount: goalAmount)
        HapticService.success(store: store)
    }
}
