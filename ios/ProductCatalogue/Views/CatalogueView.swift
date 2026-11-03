import UIKit

/// Owns catalogue presentation and selection; no services or loading tasks.
final class CatalogueView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    var onSelectCategory: ((String) -> Void)?
    var onSelectProduct: ((Int) -> Void)?
    var onRefresh: (() -> Void)?
    private let mode: CatalogueMode
    private var content = CatalogueContent(categories: [], sections: [])
    private let status = StatusView()
    private let refresh = UIRefreshControl()
    private lazy var collection = UICollectionView(frame: .zero, collectionViewLayout: layout())
    private var categoryCount: Int { content.categories.isEmpty ? 0 : 1 }

    init(mode: CatalogueMode) {
        self.mode = mode
        super.init(frame: .zero)
        backgroundColor = CatalogueStyle.background
        collection.backgroundColor = .clear
        collection.alwaysBounceVertical = true
        collection.dataSource = self
        collection.delegate = self
        collection.backgroundView = status
        collection.refreshControl = refresh
        collection.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.reuseIdentifier)
        collection.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        collection.register(CatalogueHeaderView.self, forSupplementaryViewOfKind: CatalogueHeaderView.kind, withReuseIdentifier: "Hero")
        collection.register(CatalogueSectionHeader.self, forSupplementaryViewOfKind: CatalogueSectionHeader.kind, withReuseIdentifier: "Section")
        refresh.addTarget(self, action: #selector(refreshRequested), for: .valueChanged)
        status.onRetry = { [weak self] in self?.onRefresh?() }
        addSubview(collection)
        collection.pin(to: self)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    func render(_ state: LoadState<CatalogueContent>, emptySearch: Bool) {
        content = CatalogueContent(categories: [], sections: [])
        switch state {
        case .idle: break
        case .loading: status.show(message: "Gathering the collection for you…", loading: true)
        case .failed(let message):
            refresh.endRefreshing()
            status.show(message: message, canRetry: true)
        case .loaded(let result):
            refresh.endRefreshing()
            content = result
            status.show(message: emptySearch ? "Search by product name or description." : "No products found. Try another search.")
        }
        status.isHidden = !content.categories.isEmpty || content.sections.contains { !$0.products.isEmpty }
        collection.reloadData()
        collection.collectionViewLayout.invalidateLayout()
    }

    private func layout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] index, environment in
            guard let self else { return nil }
            let categories = self.categoryCount == 1 && index == 0
            let columns = environment.traitCollection.preferredContentSizeCategory.isAccessibilityCategory
                ? 1 : (environment.container.effectiveContentSize.width >= 700 ? 3 : 2)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: categories ? .estimated(160) : .fractionalWidth(1),
                heightDimension: .estimated(categories ? 60 : 340)))
            let group: NSCollectionLayoutGroup
            if categories {
                group = .horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(160), heightDimension: .estimated(60)), subitems: [item])
            } else {
                group = .horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(340)), subitem: item, count: columns)
                group.interItemSpacing = .fixed(14)
            }
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 14
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 28, trailing: 20)
            if categories { section.orthogonalScrollingBehavior = .continuous }
            var headers: [NSCollectionLayoutBoundarySupplementaryItem] = []
            if index == 0 {
                headers.append(NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200)),
                    elementKind: CatalogueHeaderView.kind, alignment: .top))
            } else {
                headers.append(NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(40)),
                    elementKind: CatalogueSectionHeader.kind, alignment: .top))
            }
            section.boundarySupplementaryItems = headers
            return section
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        max(1, categoryCount + content.sections.count)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if categoryCount == 1 && section == 0 { return content.categories.count }
        return content.sections.indices.contains(section - categoryCount) ? content.sections[section - categoryCount].products.count : 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if categoryCount == 1 && indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as! CategoryCell
            cell.configure(content.categories[indexPath.item])
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCell.reuseIdentifier, for: indexPath) as! ProductCell
        cell.configure(with: content.sections[indexPath.section - categoryCount].products[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == CatalogueHeaderView.kind {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Hero", for: indexPath) as! CatalogueHeaderView
            header.configure(mode: mode)
            return header
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Section", for: indexPath) as! CatalogueSectionHeader
        header.configure(content.sections[indexPath.section - categoryCount].title)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if categoryCount == 1 && indexPath.section == 0 {
            onSelectCategory?(content.categories[indexPath.item])
        } else {
            onSelectProduct?(content.sections[indexPath.section - categoryCount].products[indexPath.item].id)
        }
    }

    @objc private func refreshRequested() { onRefresh?() }
}
