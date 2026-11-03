import UIKit

final class CatalogueViewController: UIViewController, UISearchBarDelegate {
    private let viewModel: CatalogueViewModel
    private let catalogueView: CatalogueView
    private var task: Task<Void, Never>?
    private var query = ""
    var onSelectCategory: ((String) -> Void)?
    var onSelectProduct: ((Int) -> Void)?

    init(viewModel: CatalogueViewModel) {
        self.viewModel = viewModel
        catalogueView = CatalogueView(mode: viewModel.mode)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }
    override func loadView() { view = catalogueView }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.mode.title
        navigationController?.navigationBar.prefersLargeTitles = false
        catalogueView.onSelectCategory = { [weak self] in self?.onSelectCategory?($0) }
        catalogueView.onSelectProduct = { [weak self] in self?.onSelectProduct?($0) }
        catalogueView.onRefresh = { [weak self] in self?.reload() }
        viewModel.onChange = { [weak self] in
            guard let self else { return }
            catalogueView.render(viewModel.state, emptySearch: viewModel.mode.isSearch && query.isEmpty)
        }
        if viewModel.mode.isSearch {
            let search = UISearchController(searchResultsController: nil)
            search.obscuresBackgroundDuringPresentation = false
            search.searchBar.placeholder = "What are you looking for?"
            search.searchBar.delegate = self
            search.searchBar.searchTextField.backgroundColor = CatalogueStyle.surface
            search.searchBar.searchTextField.textColor = CatalogueStyle.text
            navigationItem.searchController = search
            navigationItem.hidesSearchBarWhenScrolling = false
            definesPresentationContext = true
        }
        reload()
    }

    private func reload() {
        task?.cancel()
        let model = viewModel
        let query = query
        task = Task { await model.load(query: query) }
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

    deinit { task?.cancel() }
}
