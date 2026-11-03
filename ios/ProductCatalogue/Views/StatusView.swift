import UIKit

final class StatusView: UIView {
    private let symbol = UIImageView()
    private let heading = UILabel()
    private let label = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let retry = UIButton(type: .system)
    var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        symbol.contentMode = .scaleAspectFit
        symbol.tintColor = CatalogueStyle.accent
        symbol.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 36, weight: .light)
        symbol.isAccessibilityElement = false
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0
        heading.textAlignment = .center
        label.textColor = CatalogueStyle.secondaryText
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        retry.configuration = .filled()
        retry.configuration?.cornerStyle = .capsule
        retry.configuration?.baseBackgroundColor = CatalogueStyle.accent
        retry.configuration?.baseForegroundColor = CatalogueStyle.accentText
        retry.setTitle("Try again", for: .normal)
        retry.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [symbol, spinner, heading, label, retry])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
        ])
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    func show(message: String, loading: Bool = false, canRetry: Bool = false) {
        heading.text = loading ? "A few good finds, coming up" : (canRetry ? "Something got in the way" : "Find your everyday favourites")
        symbol.image = UIImage(systemName: canRetry ? "wifi.exclamationmark" : "bag")
        symbol.isHidden = loading
        label.text = message
        retry.isHidden = !canRetry
        loading ? spinner.startAnimating() : spinner.stopAnimating()
    }

    @objc private func retryTapped() { onRetry?() }
}
