import ManagedSettings
import ManagedSettingsUI
import UIKit

final class TimePayShieldConfigurationProvider: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let teal = UIColor(red: 0.35, green: 0.88, blue: 0.82, alpha: 1)
        let midnight = UIColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 1)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: midnight,
            icon: UIImage(systemName: "hourglass.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "Diese App ist gerade gesperrt",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: TimePaySharedStorage.shieldSubtitleText(),
                color: UIColor(white: 1, alpha: 0.55)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Mehr Zeit",
                color: .black
            ),
            primaryButtonBackgroundColor: teal,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Schliessen",
                color: UIColor(white: 1, alpha: 0.7)
            )
        )
    }
}
