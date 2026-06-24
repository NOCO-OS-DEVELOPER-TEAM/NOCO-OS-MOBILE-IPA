import SwiftUI

enum NOCOTheme {
    static let midnight = Color(red: 0.04, green: 0.06, blue: 0.12)
    static let deepNavy = Color(red: 0.06, green: 0.09, blue: 0.18)
    static let teal = Color(red: 0.35, green: 0.88, blue: 0.82)
    static let lavender = Color(red: 0.68, green: 0.62, blue: 1.0)
    static let mint = Color(red: 0.45, green: 0.95, blue: 0.75)

    static let accentGradient = LinearGradient(
        colors: [teal, lavender],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let holoGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.45, blue: 0.65),
            Color(red: 0.55, green: 0.45, blue: 1.0),
            Color(red: 0.35, green: 0.88, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassBorder = LinearGradient(
        colors: [.white.opacity(0.55), teal.opacity(0.35), .white.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct LiquidGlassBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            NOCOTheme.midnight.ignoresSafeArea()

            Circle()
                .fill(NOCOTheme.teal.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 75)
                .offset(x: animate ? -85 : -115, y: animate ? -210 : -175)

            Circle()
                .fill(NOCOTheme.lavender.opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 85)
                .offset(x: animate ? 125 : 95, y: animate ? 270 : 235)

            Circle()
                .fill(NOCOTheme.mint.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: animate ? 50 : 75, y: animate ? -30 : 0)

            // Subtle glass noise layer
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.03), .clear, NOCOTheme.teal.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let glow: Color?
    let content: Content

    init(glow: Color? = nil, @ViewBuilder content: () -> Content) {
        self.glow = glow
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                    if let glow {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(glow.opacity(0.08))
                            .blur(radius: 12)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(NOCOTheme.glassBorder, lineWidth: 1)
                }
                .shadow(color: (glow ?? NOCOTheme.teal).opacity(0.12), radius: 24, y: 10)
            }
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
            .overlay {
                Capsule().stroke(color.opacity(0.35), lineWidth: 1)
            }
    }
}

struct LiquidProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color, color.opacity(0.8)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: 6)
        }
    }
}

struct NOCOLogoMark: View {
    var size: CGFloat = 44
    @State private var shimmer = false

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(shimmer ? 0.3 : 0.05), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .stroke(NOCOTheme.glassBorder, lineWidth: 1)
            }
            .shadow(color: NOCOTheme.teal.opacity(0.25), radius: 12, y: 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    shimmer = true
                }
            }
    }
}

struct NOCOPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background {
                if enabled {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(NOCOTheme.accentGradient)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.15))
                            .blur(radius: 1)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.08))
                }
            }
            .foregroundStyle(enabled ? .black.opacity(0.8) : .white.opacity(0.35))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(enabled ? 0.35 : 0.1), lineWidth: 1)
            }
            .opacity(configuration.isPressed && enabled ? 0.85 : 1)
    }
}

struct NOCOSecondaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 14)
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
            .opacity(configuration.isPressed && enabled ? 0.85 : 1)
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
                .shadow(color: NOCOTheme.teal.opacity(0.2), radius: 16, y: 6)
        }
    }
}
