import UIKit

final class ProductDetailView: UIView {
    var onRetry: (() -> Void)?
    var onEnquire: (() -> Void)?
    private let status = StatusView()
    private let scroll = UIScrollView()
    private let productImage = RemoteImageView()
    private let category = CatalogueStyle.label(style: .caption1, color: CatalogueStyle.accent)
    private let name = CatalogueStyle.label(style: .title1)
    private let price = CatalogueStyle.label(style: .title2)
    private let rating = CatalogueStyle.label(style: .subheadline, color: .secondaryLabel)
    private let descriptionLabel = CatalogueStyle.label(color: .secondaryLabel)
    private let enquiry = CatalogueStyle.button("Enquire about this product", symbol: "bubble.left.and.bubble.right")

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = CatalogueStyle.background
        let imageWell = UIView()
        imageWell.backgroundColor = .white
        imageWell.layer.cornerRadius = 28
        imageWell.addSubview(productImage)
        productImage.pin(to: imageWell, inset: 24)
        productImage.contentMode = .scaleAspectFit
        productImage.isAccessibilityElement = false
        imageWell.heightAnchor.constraint(equalTo: imageWell.widthAnchor, multiplier: 0.85).isActive = true
        let stack = UIStackView(arrangedSubviews: [imageWell, category, name, price, rating,
            CatalogueStyle.label("A closer look", style: .headline), descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 18
        let footer = UIStackView(arrangedSubviews: [enquiry])
        footer.axis = .vertical
        footer.isLayoutMarginsRelativeArrangement = true
        footer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        footer.backgroundColor = CatalogueStyle.background
        [scroll, footer, status].forEach { addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: leadingAnchor), footer.trailingAnchor.constraint(equalTo: trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scroll.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor), scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: footer.topAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
            status.leadingAnchor.constraint(equalTo: leadingAnchor), status.trailingAnchor.constraint(equalTo: trailingAnchor),
            status.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor), status.bottomAnchor.constraint(equalTo: footer.topAnchor),
        ])
        status.onRetry = { [weak self] in self?.onRetry?() }
        enquiry.addTarget(self, action: #selector(enquire), for: .touchUpInside)
        enquiry.isEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    func render(_ state: LoadState<Product>) {
        scroll.isHidden = true
        status.isHidden = false
        enquiry.isEnabled = false
        switch state {
        case .idle: break
        case .loading: status.show(message: "Getting the details…", loading: true)
        case .failed(let message): status.show(message: message, canRetry: true)
        case .loaded(let product):
            scroll.isHidden = false
            status.isHidden = true
            enquiry.isEnabled = true
            productImage.load(product.imageUrl)
            category.text = product.category.replacingOccurrences(of: "-", with: " ").uppercased()
            name.text = product.title
            price.text = "Price · \(product.displayPrice)"
            rating.text = "★ \(product.rating.value.formatted()) / 5 · \(product.rating.count) reviews"
            descriptionLabel.text = product.description
        }
    }

    @objc private func enquire() { onEnquire?() }
}
