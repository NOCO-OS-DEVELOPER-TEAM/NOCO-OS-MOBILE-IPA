import SwiftUI
import UIKit

extension Notification.Name {
    static let liveCashDeviceDidShake = Notification.Name("liveCashDeviceDidShake")
}

/// Invisible responder that forwards shake gestures app-wide.
struct ShakeDetectorRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ShakeViewController {
        ShakeViewController()
    }

    func updateUIViewController(_ uiViewController: ShakeViewController, context: Context) {}
}

final class ShakeViewController: UIViewController {
    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .liveCashDeviceDidShake, object: nil)
    }
}

struct ShakeDetectorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ShakeDetectorRepresentable()
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func onShake() -> some View {
        modifier(ShakeDetectorModifier())
    }
}
