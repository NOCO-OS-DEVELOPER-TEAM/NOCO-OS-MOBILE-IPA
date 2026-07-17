import SwiftUI

/// Shared motion tokens, press styles, and appear transitions for a premium feel.
enum LiveCashMotion {
    static let pressSpring = Animation.spring(response: 0.28, dampingFraction: 0.72)
    static let panelSpring = Animation.spring(response: 0.38, dampingFraction: 0.86)
    static let softSpring = Animation.spring(response: 0.48, dampingFraction: 0.86)
    static let appearEase = Animation.easeOut(duration: 0.42)
    static let crossfade = Animation.easeInOut(duration: 0.28)
    static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.78)

    @MainActor
    static func resolved(_ base: Animation, store: FinanceStore) -> Animation {
        switch store.appSettings.ui.animationLevel {
        case .low:
            return .easeOut(duration: 0.12)
        case .medium:
            return base
        case .high:
            return base
        }
    }

    @MainActor
    static func staggerDelay(_ index: Int, store: FinanceStore) -> Double {
        switch store.appSettings.ui.animationLevel {
        case .low: return 0
        case .medium: return Double(index) * 0.06
        case .high: return Double(index) * 0.09
        }
    }

    @MainActor
    static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}

/// Soft scale + opacity on press — primary interactive chrome.
struct PremiumPressStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var pressedOpacity: Double = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(LiveCashMotion.pressSpring, value: configuration.isPressed)
    }
}

/// Lighter press for list rows / chips.
struct SoftPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(LiveCashMotion.snappy, value: configuration.isPressed)
    }
}

/// Fade + slight rise on first appear (respects Reduce Motion).
struct AppearFadeModifier: ViewModifier {
    var delay: Double = 0
    var offsetY: CGFloat = 14
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : (LiveCashMotion.reduceMotion ? 0 : offsetY))
            .onAppear {
                guard !shown else { return }
                if LiveCashMotion.reduceMotion {
                    shown = true
                    return
                }
                withAnimation(LiveCashMotion.appearEase.delay(delay)) {
                    shown = true
                }
            }
    }
}

/// Scale-in for cards / tiles.
struct AppearScaleModifier: ViewModifier {
    var delay: Double = 0
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown ? 1 : (LiveCashMotion.reduceMotion ? 1 : 0.96))
            .onAppear {
                guard !shown else { return }
                if LiveCashMotion.reduceMotion {
                    shown = true
                    return
                }
                withAnimation(LiveCashMotion.softSpring.delay(delay)) {
                    shown = true
                }
            }
    }
}

/// Soft highlight pulse once (e.g. after save).
struct SuccessFlashModifier: ViewModifier {
    @Binding var trigger: Bool
    @State private var flash = false

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LiveCashTheme.accent.opacity(flash ? 0.18 : 0))
                    .allowsHitTesting(false)
            }
            .onChange(of: trigger) { _, on in
                guard on else { return }
                withAnimation(.easeOut(duration: 0.2)) { flash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeOut(duration: 0.45)) { flash = false }
                    trigger = false
                }
            }
    }
}

extension View {
    func appearFade(delay: Double = 0, offsetY: CGFloat = 14) -> some View {
        modifier(AppearFadeModifier(delay: delay, offsetY: offsetY))
    }

    func appearScale(delay: Double = 0) -> some View {
        modifier(AppearScaleModifier(delay: delay))
    }

    func successFlash(_ trigger: Binding<Bool>) -> some View {
        modifier(SuccessFlashModifier(trigger: trigger))
    }

    /// Crossfade content when `value` changes.
    func premiumCrossfade<V: Equatable>(value: V) -> some View {
        animation(LiveCashMotion.crossfade, value: value)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    func listRowAppear(index: Int) -> some View {
        appearFade(delay: min(Double(index) * 0.04, 0.28), offsetY: 8)
    }
}
