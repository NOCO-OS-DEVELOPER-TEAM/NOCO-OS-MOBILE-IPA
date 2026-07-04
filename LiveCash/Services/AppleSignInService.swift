import AuthenticationServices
import SwiftUI

@MainActor
final class AppleSignInService: NSObject, ObservableObject {
    static let shared = AppleSignInService()

    @Published private(set) var userIdentifier: String?
    @Published private(set) var isSignedIn = false

    private let userIdKey = "livecash_apple_user_id"

    override init() {
        super.init()
        userIdentifier = UserDefaults.standard.string(forKey: userIdKey)
        isSignedIn = userIdentifier != nil
    }

    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func signOut() {
        userIdentifier = nil
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }

    private func persist(_ id: String) {
        userIdentifier = id
        isSignedIn = true
        UserDefaults.standard.set(id, forKey: userIdKey)
    }
}

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        persist(credential.user)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // User cancelled or failed — no-op
    }
}

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
