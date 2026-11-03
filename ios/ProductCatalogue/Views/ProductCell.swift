import UIKit

final class ProductCell: UITableViewCell {
    static let reuseIdentifier = "ProductCell"
    private let productImage = RemoteImageView()
    private let title = UILabel()
    private let category = UILabel()
    private let price = UILabel()
    private let rating = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        let imageContainer = UIView()
        imageContainer.backgroundColor = .white
        imageContainer.layer.cornerRadius = 14
        productImage.contentMode = .scaleAspectFit
        productImage.isAccessibilityElement = false
        productImage.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(productImage)
        configure(title, style: .headline, color: .label)
        configure(category, style: .caption1, color: .secondaryLabel)
        configure(price, style: .title3, color: .label)
        configure(rating, style: .subheadline, color: .secondaryLabel)
        let text = UIStackView(arrangedSubviews: [category, title, price, rating])
        text.axis = .vertical
        text.spacing = 7
        let row = UIStackView(arrangedSubviews: [imageContainer, text])
        row.spacing = 18
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            imageContainer.widthAnchor.constraint(equalToConstant: 88),
            imageContainer.heightAnchor.constraint(equalToConstant: 108),
            productImage.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor, constant: 10),
            productImage.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: -10),
            productImage.topAnchor.constraint(equalTo: imageContainer.topAnchor, constant: 10),
            productImage.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: -10),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
        ])
    }

    private func configure(_ label: UILabel, style: UIFont.TextStyle, color: UIColor) {
        label.font = .preferredFont(forTextStyle: style)
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    func configure(with product: Product) {
        title.text = product.title
        category.text = product.category.uppercased()
        price.text = "Price · \(product.displayPrice)"
        rating.text = "★ \(product.rating.value.formatted()) · \(product.rating.count) reviews"
        productImage.load(product.imageUrl)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        productImage.load(nil)
        [title, category, price, rating].forEach { $0.text = nil }
    }
}
