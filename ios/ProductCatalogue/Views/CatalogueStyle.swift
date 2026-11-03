import UIKit

/// Shared visual choices; screen behavior stays in each view and view model.
@MainActor
enum CatalogueStyle {
    static let accent = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 1, green: 0.65, blue: 0.42, alpha: 1)
        : UIColor(red: 0.65, green: 0.24, blue: 0.10, alpha: 1) }
    static let background = UIColor { $0.userInterfaceStyle == .dark
        ? .systemBackground : UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1) }
    static let accentText = UIColor { $0.userInterfaceStyle == .dark ? .black : .white }
    static let surface = UIColor.secondarySystemGroupedBackground

    static func label(_ text: String = "", style: UIFont.TextStyle = .body,
                      color: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
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
