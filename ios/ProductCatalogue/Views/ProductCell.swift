import UIKit

final class ProductCell: UITableViewCell {
    static let reuseIdentifier = "ProductCell"
    private let productImage = RemoteImageView()
    private let title = UILabel()
    private let subtitle = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        productImage.contentMode = .scaleAspectFit
        productImage.isAccessibilityElement = false
        productImage.translatesAutoresizingMaskIntoConstraints = false
        title.font = .preferredFont(forTextStyle: .headline)
        title.numberOfLines = 0
        title.adjustsFontForContentSizeCategory = true
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0
        subtitle.adjustsFontForContentSizeCategory = true
        let text = UIStackView(arrangedSubviews: [title, subtitle])
        text.axis = .vertical
        text.spacing = 8
        let row = UIStackView(arrangedSubviews: [productImage, text])
        row.spacing = 16
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            productImage.widthAnchor.constraint(equalToConstant: 64),
            productImage.heightAnchor.constraint(equalToConstant: 72),
            row.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    func configure(with product: Product) {
        title.text = product.title
        subtitle.text = "Price: \(product.displayPrice) · Rating: \(product.rating.value.formatted())/5"
        productImage.load(product.imageUrl)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        productImage.load(nil)
        title.text = nil
        subtitle.text = nil
    }
}
