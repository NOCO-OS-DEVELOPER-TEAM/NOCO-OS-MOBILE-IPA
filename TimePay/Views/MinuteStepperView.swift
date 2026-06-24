import SwiftUI

/// Minuten-Auswahl in 0,5-Minuten-Schritten mit Slider, Stepper und Direkteingabe.
struct MinuteStepperView: View {
    @Binding var minutes: Double
    let maxMinutes: Double
    let accent: Color
    let label: String

    @State private var textInput = ""
    @FocusState private var fieldFocused: Bool

    private var minMinutes: Double { 0.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(displayText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
            }

            Slider(
                value: $minutes,
                in: minMinutes...max(minMinutes, maxMinutes),
                step: 0.5
            )
            .tint(accent)

            HStack(spacing: 10) {
                stepButton("-0,5", delta: -0.5)
                stepButton("-1", delta: -1)
                Spacer()
                TextField("Min", text: $textInput)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.body.monospacedDigit().weight(.semibold))
                    .frame(width: 72)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .focused($fieldFocused)
                    .onSubmit { applyTextInput() }
                    .onChange(of: fieldFocused) { _, focused in
                        if !focused { applyTextInput() }
                    }
                Spacer()
                stepButton("+1", delta: 1)
                stepButton("+0,5", delta: 0.5)
            }

            if maxMinutes < minMinutes {
                Text("Nicht genug Guthaben auf dem Konto.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .onAppear { syncTextFromValue() }
        .onChange(of: minutes) { _, _ in
            if !fieldFocused { syncTextFromValue() }
        }
    }

    private var displayText: String {
        let half = Int((minutes * 2).rounded())
        return TimePayFormat.halfMinutes(half)
    }

    private func stepButton(_ title: String, delta: Double) -> some View {
        Button {
            let next = (minutes + delta * 2).rounded() / 2
            minutes = clamp(next)
            syncTextFromValue()
        } label: {
            Text(title)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accent.opacity(0.14), in: Capsule())
                .foregroundStyle(accent)
        }
        .buttonStyle(.plain)
        .disabled(clamp(minutes + delta) == minutes && delta < 0)
    }

    private func applyTextInput() {
        let normalized = textInput
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(normalized), value > 0 else {
            syncTextFromValue()
            return
        }
        let snapped = (value * 2).rounded() / 2
        minutes = clamp(snapped)
        syncTextFromValue()
    }

    private func syncTextFromValue() {
        let half = Int((minutes * 2).rounded())
        if half % 2 == 0 {
            textInput = "\(half / 2)"
        } else {
            textInput = "\(half / 2),5"
        }
    }

    private func clamp(_ value: Double) -> Double {
        let snapped = (value * 2).rounded() / 2
        return min(max(snapped, minMinutes), max(minMinutes, maxMinutes))
    }
}
