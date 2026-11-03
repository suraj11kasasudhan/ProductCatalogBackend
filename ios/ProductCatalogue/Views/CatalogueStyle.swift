import UIKit

/// Shared visual choices; screen behavior stays in each view and view model.
@MainActor
enum CatalogueStyle {
    static let accent = color(light: 0xA33760, dark: 0xF5A6C3)
    static let background = color(light: 0xFFF0F5, dark: 0x24151E)
    static let surface = color(light: 0xFFE1EB, dark: 0x35202D)
    static let imageBackground = color(light: 0xFFF7FA, dark: 0x412A37)
    static let categoryBackground = color(light: 0xF7CDDD, dark: 0x4B2C3C)
    static let text = color(light: 0x4B2436, dark: 0xFFEAF2)
    static let secondaryText = color(light: 0x795063, dark: 0xD9B3C4)
    static let accentText = color(light: 0xFFFFFF, dark: 0x321322)

    private static func color(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        }
    }

    static func configureChrome() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = background
        navigation.shadowColor = .clear
        navigation.titleTextAttributes = [.foregroundColor: text]
        navigation.largeTitleTextAttributes = [.foregroundColor: text]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = surface
        tab.shadowColor = .clear
        for item in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            item.normal.iconColor = secondaryText
            item.normal.titleTextAttributes = [.foregroundColor: secondaryText]
            item.selected.iconColor = accent
            item.selected.titleTextAttributes = [.foregroundColor: accent]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

    static func label(_ text: String = "", style: UIFont.TextStyle = .body,
                      color: UIColor? = nil) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color ?? self.text
        label.numberOfLines = 0
        return label
    }

    static func button(_ title: String, symbol: String) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 10
        configuration.baseBackgroundColor = accent
        configuration.baseForegroundColor = accentText
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20)
        return UIButton(configuration: configuration)
    }
}

extension UIView {
    func pin(to parent: UIView, inset: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -inset),
            topAnchor.constraint(equalTo: parent.topAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -inset),
        ])
    }
}
