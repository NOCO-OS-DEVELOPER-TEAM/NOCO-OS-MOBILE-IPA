import SwiftUI

enum NOCOTheme {
    static let midnight = Color(red: 0.04, green: 0.06, blue: 0.12)
    static let deepNavy = Color(red: 0.06, green: 0.09, blue: 0.18)
    static let teal = Color(red: 0.35, green: 0.88, blue: 0.82)
    static let lavender = Color(red: 0.68, green: 0.62, blue: 1.0)
    static let mint = Color(red: 0.45, green: 0.95, blue: 0.75)
    static let coral = Color(red: 1.0, green: 0.55, blue: 0.45)

    static let accentGradient = LinearGradient(
        colors: [teal, lavender],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let holoGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.45, blue: 0.65),
            Color(red: 0.55, green: 0.45, blue: 1.0),
            Color(red: 0.35, green: 0.88, blue: 0.95),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassBorder = LinearGradient(
        colors: [.white.opacity(0.55), teal.opacity(0.35), .white.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardRadius: CGFloat = 24
    static let heroRadius: CGFloat = 32
}

struct LiquidGlassBackground: View {
    @State private var animate = false
    @State private var drift = false

    var body: some View {
        ZStack {
            NOCOTheme.midnight.ignoresSafeArea()

            Circle()
                .fill(NOCOTheme.teal.opacity(0.22))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: animate ? -100 : -140, y: animate ? -200 : -160)
                .scaleEffect(drift ? 1.08 : 0.92)

            Circle()
                .fill(NOCOTheme.lavender.opacity(0.18))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: animate ? 140 : 90, y: animate ? 260 : 220)
                .scaleEffect(drift ? 0.94 : 1.06)

            Circle()
                .fill(NOCOTheme.mint.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: drift ? 40 : 90, y: drift ? 40 : -10)

            Circle()
                .fill(NOCOTheme.coral.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 55)
                .offset(x: drift ? -60 : -20, y: drift ? 320 : 280)

            LinearGradient(
                colors: [.white.opacity(0.05), .clear, NOCOTheme.teal.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate = true
            }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let glow: Color?
    let padding: CGFloat
    let content: Content

    init(glow: Color? = nil, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.glow = glow
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: NOCOTheme.cardRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: NOCOTheme.cardRadius, style: .continuous)
                        .fill(Color.white.opacity(0.035))
                    if let glow {
                        RoundedRectangle(cornerRadius: NOCOTheme.cardRadius, style: .continuous)
                            .fill(glow.opacity(0.07))
                            .blur(radius: 14)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: NOCOTheme.cardRadius, style: .continuous)
                        .stroke(NOCOTheme.glassBorder, lineWidth: 1)
                }
                .shadow(color: (glow ?? NOCOTheme.teal).opacity(0.1), radius: 20, y: 8)
            }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String

    init(_ title: String, subtitle: String? = nil, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(NOCOTheme.teal)
                .frame(width: 32, height: 32)
                .background(NOCOTheme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
        }
    }
}

struct MetricTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .padding(8)
                .background(color.opacity(0.15), in: Circle())
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.04))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        }
    }
}

struct ActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(NOCOTheme.glassBorder, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
        .overlay { Capsule().stroke(color.opacity(0.3), lineWidth: 1) }
    }
}

struct GlassPill: View {
    let text: String
    var color: Color = NOCOTheme.teal

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().stroke(color.opacity(0.35), lineWidth: 1) }
    }
}

struct LiveCountdownText: View {
    let endDate: Date
    var font: Font = .system(.title2, design: .monospaced).weight(.bold)
    var color: Color = NOCOTheme.teal

    var body: some View {
        Text(timerInterval: Date()...endDate, countsDown: true)
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}

struct LiveSessionProgressBar: View {
    let start: Date
    let end: Date
    var tint: Color = NOCOTheme.teal

    var body: some View {
        ProgressView(timerInterval: start...end, countsDown: true)
            .tint(tint)
            .scaleEffect(y: 1.4)
    }
}

struct LiquidProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.4), color, color.opacity(0.85)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.35), radius: 8)
        }
    }
}

struct NOCOLogoMark: View {
    var size: CGFloat = 44
    @State private var shimmer = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [NOCOTheme.deepNavy, NOCOTheme.midnight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
                .opacity(0.92)

            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: size * 0.52, weight: .semibold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(NOCOTheme.teal, .white.opacity(0.85))
                .opacity(0.18)

            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(shimmer ? 0.32 : 0.06), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .stroke(NOCOTheme.glassBorder, lineWidth: 1.2)

            Circle()
                .stroke(NOCOTheme.holoGradient, lineWidth: 1.5)
                .scaleEffect(pulse ? 1.08 : 0.94)
                .opacity(pulse ? 0.35 : 0.12)
                .blur(radius: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: NOCOTheme.teal.opacity(0.28), radius: 14, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                shimmer = true
            }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct GateOrbView: View {
    let isOpen: Bool
    let progress: Double
    var size: CGFloat = 180
    var flashExpired: Bool = false
    var isUrgent: Bool = false

    @State private var breathe = false
    @State private var expirePulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill((isOpen ? NOCOTheme.teal : Color.orange).opacity(isUrgent ? 0.28 : 0.12))
                .frame(width: size * 1.15, height: size * 1.15)
                .blur(radius: 28)
                .scaleEffect(flashExpired ? 1.2 : (breathe ? 1.05 : 0.92))
                .animation(.spring(response: 0.45, dampingFraction: 0.55), value: flashExpired)

            if flashExpired {
                Circle()
                    .stroke(NOCOTheme.coral.opacity(0.8), lineWidth: 4)
                    .frame(width: size * 1.1, height: size * 1.1)
                    .scaleEffect(expirePulse ? 1.15 : 0.9)
                    .opacity(expirePulse ? 0 : 0.9)
            }

            LiquidProgressRing(
                progress: isOpen ? progress : 0,
                color: flashExpired ? NOCOTheme.coral : (isOpen ? NOCOTheme.teal : .orange),
                lineWidth: 8
            )
            .frame(width: size, height: size)

            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size * 0.72, height: size * 0.72)
                .overlay {
                    Circle()
                        .stroke(NOCOTheme.glassBorder, lineWidth: 1)
                }

            Image(systemName: flashExpired ? "lock.fill" : (isOpen ? "lock.open.fill" : "lock.fill"))
                .font(.system(size: size * 0.22, weight: .semibold))
                .foregroundStyle(flashExpired ? NOCOTheme.coral : (isOpen ? NOCOTheme.teal : .orange))
                .symbolEffect(.bounce, value: flashExpired)
                .symbolEffect(.pulse, options: isOpen && !flashExpired ? .repeating : .nonRepeating)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .onChange(of: flashExpired) { _, flash in
            guard flash else { return }
            expirePulse = false
            withAnimation(.easeOut(duration: 1.2)) {
                expirePulse = true
            }
        }
    }
}

struct GlassAppTile: View {
    let app: ProtectedApp
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: app.symbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(app.isEnabled ? app.accent : .white.opacity(0.35))
                        .frame(width: 52, height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(app.isEnabled ? app.accent.opacity(0.14) : .white.opacity(0.04))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(app.isEnabled ? app.accent.opacity(0.35) : .white.opacity(0.08), lineWidth: 1)
                                }
                        }

                    if app.isEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(NOCOTheme.mint)
                            .offset(x: 6, y: -6)
                    }
                }

                Text(app.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(app.isEnabled ? app.accent.opacity(0.25) : .white.opacity(0.06), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(GlassScaleButtonStyle())
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                Text(title)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isSelected ? .black.opacity(0.85) : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule().fill(NOCOTheme.accentGradient)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay { Capsule().stroke(.white.opacity(0.1), lineWidth: 1) }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct GlassScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SetupProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            LiquidProgressRing(progress: progress, color: NOCOTheme.mint, lineWidth: 5)
                .frame(width: 44, height: 44)
            Text("\(Int(progress * 100))%")
                .font(.caption2.weight(.bold))
                .foregroundStyle(NOCOTheme.mint)
        }
    }
}

struct NOCOPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
            .background {
                if enabled {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(NOCOTheme.accentGradient)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.12))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.08))
                }
            }
            .foregroundStyle(enabled ? .black.opacity(0.82) : .white.opacity(0.35))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(enabled ? 0.3 : 0.1), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && enabled ? 0.98 : 1)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

struct NOCOSecondaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        enabled ? NOCOTheme.glassBorder : LinearGradient(colors: [.white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            }
            .foregroundStyle(enabled ? .white : .white.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed && enabled ? 0.98 : 1)
    }
}

struct GlassToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(NOCOTheme.teal)
            Text(message)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay { Capsule().stroke(NOCOTheme.glassBorder, lineWidth: 1) }
                .shadow(color: NOCOTheme.teal.opacity(0.18), radius: 16, y: 6)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String
    var color: Color = NOCOTheme.teal

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
    }
}
