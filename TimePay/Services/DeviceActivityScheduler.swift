import Foundation

#if canImport(DeviceActivity)
import DeviceActivity

enum DeviceActivityScheduler {
    static func scheduleRelock(at endDate: Date) {
        let center = DeviceActivityCenter()
        center.stopMonitoring([TimePayActivity.unlockSession])

        guard endDate > Date() else { return }

        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute, .second], from: Date())
        let end = calendar.dateComponents([.hour, .minute, .second], from: endDate)

        let schedule = DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: false
        )

        do {
            try center.startMonitoring(TimePayActivity.unlockSession, during: schedule)
        } catch {
            // DeviceActivity may fail without proper entitlements; foreground timer still works.
        }
    }

    static func cancelRelockSchedule() {
        DeviceActivityCenter().stopMonitoring([TimePayActivity.unlockSession])
    }
}
#endif
