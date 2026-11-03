import UIKit

final class ProductCell: UICollectionViewCell {
    static let reuseIdentifier = "ProductCell"
    private let productImage = RemoteImageView()
    private let category = CatalogueStyle.label(style: .caption2, color: CatalogueStyle.secondaryText)
    private let title = CatalogueStyle.label(style: .headline)
    private let price = CatalogueStyle.label(style: .title3)
    private let rating = CatalogueStyle.label(style: .caption1, color: CatalogueStyle.secondaryText)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = CatalogueStyle.surface
        contentView.layer.cornerRadius = 22
        contentView.layer.cornerCurve = .continuous
        let imageWell = UIView()
        imageWell.backgroundColor = CatalogueStyle.imageBackground
        imageWell.layer.cornerRadius = 16
        productImage.contentMode = .scaleAspectFit
        productImage.isAccessibilityElement = false
        imageWell.addSubview(productImage)
        productImage.pin(to: imageWell, inset: 12)
        imageWell.heightAnchor.constraint(equalTo: imageWell.widthAnchor, multiplier: 0.9).isActive = true
        let stack = UIStackView(arrangedSubviews: [imageWell, category, title, price, rating])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(14, after: imageWell)
        contentView.addSubview(stack)
        stack.pin(to: contentView, inset: 12)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    func configure(with product: Product) {
        category.text = product.category.replacingOccurrences(of: "-", with: " ").uppercased()
        title.text = product.title
        price.text = "Price · \(product.displayPrice)"
        rating.text = "★ \(product.rating.value.formatted()) · \(product.rating.count) reviews"
        productImage.load(product.imageUrl)
        accessibilityLabel = "\(product.title), price \(product.displayPrice), rating \(product.rating.value.formatted()) out of 5"
        accessibilityHint = "Opens product details"
    }

    override var isHighlighted: Bool {
        didSet { contentView.alpha = isHighlighted ? 0.65 : 1 }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        productImage.load(nil)
        accessibilityLabel = nil
    }
}
