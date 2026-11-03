import UIKit

final class CatalogueViewController: UITableViewController, UISearchBarDelegate {
    private let viewModel: CatalogueViewModel
    var onSelectCategory: ((String) -> Void)?
    var onSelectProduct: ((Int) -> Void)?
    private let statusView = StatusView()
    private var content = CatalogueContent(categories: [], sections: [])
    private var task: Task<Void, Never>?
    private var query = ""

    init(viewModel: CatalogueViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.mode.title
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
        tableView.backgroundView = statusView
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        statusView.onRetry = { [weak self] in self?.reload() }
        viewModel.onChange = { [weak self] in self?.render() }
        if viewModel.mode.isSearch {
            let search = UISearchController(searchResultsController: nil)
            search.obscuresBackgroundDuringPresentation = false
            search.searchBar.placeholder = "Search products"
            search.searchBar.delegate = self
            navigationItem.searchController = search
            navigationItem.hidesSearchBarWhenScrolling = false
            definesPresentationContext = true
        }
        reload()
    }

    private func reload() {
        task?.cancel()
        let model = viewModel
        let term = query
        task = Task { await model.load(query: term) }
    }

    private func render() {
        content = CatalogueContent(categories: [], sections: [])
        switch viewModel.state {
        case .idle: break
        case .loading:
            statusView.show(message: "Loading products…", loading: true)
        case .failed(let message):
            refreshControl?.endRefreshing()
            statusView.show(message: message, canRetry: true)
        case .loaded(let result):
            refreshControl?.endRefreshing()
            content = result
            statusView.show(message: viewModel.mode.isSearch && query.isEmpty
                ? "Search by product name or description."
                : "No matching products found.")
        }
        statusView.isHidden = !content.categories.isEmpty || content.sections.contains { !$0.products.isEmpty }
        tableView.reloadData()
    }

    private var categorySectionCount: Int { content.categories.isEmpty ? 0 : 1 }

    override func numberOfSections(in tableView: UITableView) -> Int {
        categorySectionCount + content.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if categorySectionCount == 1 && section == 0 { return content.categories.count }
        return content.sections[section - categorySectionCount].products.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if categorySectionCount == 1 && section == 0 { return "Categories" }
        return content.sections[section - categorySectionCount].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if categorySectionCount == 1 && indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Category") ?? UITableViewCell(style: .default, reuseIdentifier: "Category")
            var configuration = cell.defaultContentConfiguration()
            configuration.text = content.categories[indexPath.row].capitalized
            configuration.image = UIImage(systemName: "square.grid.2x2")
            cell.contentConfiguration = configuration
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.reuseIdentifier, for: indexPath) as? ProductCell else {
            return UITableViewCell()
        }
        cell.configure(with: content.sections[indexPath.section - categorySectionCount].products[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if categorySectionCount == 1 && indexPath.section == 0 {
            let category = content.categories[indexPath.row]
            onSelectCategory?(category)
        } else {
            let product = content.sections[indexPath.section - categorySectionCount].products[indexPath.row]
            onSelectProduct?(product.id)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        query = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        searchBar.resignFirstResponder()
        reload()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        query = ""
        reload()
    }

    @objc private func refresh() { reload() }
    deinit { task?.cancel() }
}
