import SwiftUI

enum NOCOTheme {
    static let midnight = Color(red: 0.04, green: 0.06, blue: 0.12)
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
}

struct LiquidGlassBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            NOCOTheme.midnight.ignoresSafeArea()
            Circle()
                .fill(NOCOTheme.teal.opacity(0.2))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: animate ? -80 : -110, y: animate ? -200 : -170)
            Circle()
                .fill(NOCOTheme.lavender.opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: animate ? 120 : 90, y: animate ? 260 : 230)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), NOCOTheme.teal.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
    }
}

struct NOCOLogoMark: View {
    var size: CGFloat = 44

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            }
    }
}
