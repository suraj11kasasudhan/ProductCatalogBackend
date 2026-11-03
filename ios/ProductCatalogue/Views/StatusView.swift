import UIKit

final class StatusView: UIView {
    private let label = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let retry = UIButton(type: .system)
    var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        retry.setTitle("Try again", for: .normal)
        retry.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [spinner, label, retry])
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
        label.text = message
        retry.isHidden = !canRetry
        loading ? spinner.startAnimating() : spinner.stopAnimating()
    }

    @objc private func retryTapped() { onRetry?() }
}
