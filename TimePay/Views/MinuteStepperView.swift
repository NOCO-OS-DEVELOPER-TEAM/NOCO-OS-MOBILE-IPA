import SwiftUI

/// Minuten-Auswahl in 1-Minuten-Schritten.
struct MinuteStepperView: View {
    @Binding var minutes: Double
    let maxMinutes: Double
    let accent: Color
    let label: String

    @State private var textInput = ""
    @FocusState private var fieldFocused: Bool

    private var minMinutes: Double { 1 }

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
                step: 1
            )
            .tint(accent)

            HStack(spacing: 10) {
                stepButton("-5", delta: -5)
                stepButton("-1", delta: -1)
                Spacer()
                TextField("Min", text: $textInput)
                    .keyboardType(.numberPad)
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
                stepButton("+5", delta: 5)
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
        let whole = Int(minutes.rounded())
        return whole == 1 ? "1 Min" : "\(whole) Min"
    }

    private func stepButton(_ title: String, delta: Double) -> some View {
        Button {
            minutes = clamp(minutes + delta)
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
        guard let value = Double(normalized), value >= 1 else {
            syncTextFromValue()
            return
        }
        minutes = clamp(value.rounded())
        syncTextFromValue()
    }

    private func syncTextFromValue() {
        textInput = "\(Int(minutes.rounded()))"
    }

    private func clamp(_ value: Double) -> Double {
        let snapped = value.rounded()
        return min(max(snapped, minMinutes), max(minMinutes, maxMinutes))
    }
}
