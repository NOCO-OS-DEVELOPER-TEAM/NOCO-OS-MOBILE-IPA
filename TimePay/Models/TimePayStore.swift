import Foundation
import SwiftUI

struct ProductiveTask: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let icon: String

    static let defaults: [ProductiveTask] = [
        .init(id: "read", title: "Lesen", icon: "book.fill"),
        .init(id: "learn", title: "Lernen", icon: "brain.head.profile"),
        .init(id: "sport", title: "Sport", icon: "figure.run"),
        .init(id: "meditate", title: "Meditieren", icon: "leaf.fill"),
        .init(id: "walk", title: "Spazieren", icon: "figure.walk"),
    ]
}

@MainActor
final class TimePayStore: ObservableObject {
    @Published var balanceMinutes: Int {
        didSet { persist() }
    }
    @Published var spendMinutes: Double = 5
    @Published var earnMinutes: Double = 10
    @Published var selectedTask: ProductiveTask = ProductiveTask.defaults[0]
    @Published var isEarningSessionActive = false
    @Published var earnSessionRemaining: Int = 0
    @Published var unlockSessionRemaining: Int = 0
    @Published var pendingUnlockFromShield = false
    @Published var showUnlockSheet = false
    @Published var showEarnSheet = false
    @Published var toastMessage: String?

    private var earnTimer: Timer?
    private var unlockTimer: Timer?
    private let balanceKey = "timepay.balance"

    var formattedBalance: String {
        "\(balanceMinutes) Min"
    }

    init() {
        let saved = UserDefaults.standard.integer(forKey: balanceKey)
        balanceMinutes = saved > 0 ? saved : 20
    }

    func confirmUnlock(onUnlock: @escaping (Int) -> Void, onRelock: @escaping () -> Void) {
        let minutes = Int(spendMinutes.rounded())
        guard minutes > 0, minutes <= balanceMinutes else {
            toast("Nicht genug Zeit auf dem Konto.")
            return
        }
        balanceMinutes -= minutes
        unlockSessionRemaining = minutes * 60
        toast("Apps für \(minutes) Min freigeschaltet.")
        onUnlock(minutes)
        startUnlockCountdown(onRelock: onRelock)
        showUnlockSheet = false
    }

    func startEarnSession() {
        let target = Int(earnMinutes.rounded())
        guard target > 0 else { return }
        isEarningSessionActive = true
        earnSessionRemaining = target * 60
        earnTimer?.invalidate()
        earnTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickEarn()
            }
        }
        showEarnSheet = false
    }

    func cancelEarnSession() {
        earnTimer?.invalidate()
        isEarningSessionActive = false
        earnSessionRemaining = 0
    }

    private func tickEarn() {
        guard earnSessionRemaining > 0 else { return }
        earnSessionRemaining -= 1
        if earnSessionRemaining == 0 {
            let earned = Int(earnMinutes.rounded())
            balanceMinutes += earned
            isEarningSessionActive = false
            earnTimer?.invalidate()
            toast("+\(earned) Min gutgeschrieben!")
        }
    }

    private func startUnlockCountdown(onRelock: @escaping () -> Void) {
        unlockTimer?.invalidate()
        unlockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.unlockSessionRemaining > 0 {
                    self.unlockSessionRemaining -= 1
                }
                if self.unlockSessionRemaining == 0 {
                    self.unlockTimer?.invalidate()
                    self.toast("Zeit abgelaufen — Apps wieder gesperrt.")
                    onRelock()
                }
            }
        }
    }

    func toast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.toastMessage == message { self?.toastMessage = nil }
        }
    }

    private func persist() {
        UserDefaults.standard.set(balanceMinutes, forKey: balanceKey)
    }
}
