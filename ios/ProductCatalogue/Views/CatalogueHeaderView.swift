import UIKit

final class CatalogueHeaderView: UICollectionReusableView {
    static let kind = "CatalogueHeader"
    private let eyebrow = CatalogueStyle.label("THE EVERYDAY EDIT", style: .caption1, color: CatalogueStyle.accent)
    private let title = CatalogueStyle.label(style: .largeTitle)
    private let subtitle = CatalogueStyle.label(style: .subheadline, color: CatalogueStyle.secondaryText)

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [eyebrow, title, subtitle])
        stack.axis = .vertical
        stack.spacing = 10
        addSubview(stack)
        stack.pin(to: self, inset: 4)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    func configure(mode: CatalogueMode) {
        switch mode {
        case .home:
            title.text = "Good finds.\nEvery day."
            subtitle.text = "Explore the collection. Find your next favourite."
        case .search:
            title.text = "Made for\nyour search."
            subtitle.text = "Search by name or description to find your kind of thing."
        case .category(let name):
            title.text = name.replacingOccurrences(of: "-", with: " ").capitalized
            subtitle.text = "A closer look at the things you love."
        }
    }
}

final class CatalogueSectionHeader: UICollectionReusableView {
    static let kind = UICollectionView.elementKindSectionHeader
    private let title = CatalogueStyle.label(style: .title2)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(title)
        title.pin(to: self, inset: 4)
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }
    func configure(_ text: String) { title.text = text }
}

final class CategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryCell"
    private let label = CatalogueStyle.label(style: .subheadline)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = CatalogueStyle.categoryBackground
        contentView.layer.cornerRadius = 18
        contentView.layer.cornerCurve = .continuous
        contentView.addSubview(label)
        label.pin(to: contentView, inset: 16)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }
    func configure(_ name: String) {
        label.text = name.replacingOccurrences(of: "-", with: " ").capitalized + "  ↗"
        accessibilityLabel = name
        accessibilityHint = "Browse this category"
    }
    override var isHighlighted: Bool { didSet { contentView.alpha = isHighlighted ? 0.65 : 1 } }
}
