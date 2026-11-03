import UIKit

final class ProductDetailViewController: UIViewController {
    private let viewModel: ProductDetailViewModel
    private let detailView = ProductDetailView()
    private var task: Task<Void, Never>?
    var onEnquire: ((Product) -> Void)?

    init(viewModel: ProductDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }
    override func loadView() { view = detailView }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The details"
        navigationItem.largeTitleDisplayMode = .never
        detailView.onRetry = { [weak self] in self?.reload() }
        detailView.onEnquire = { [weak self] in
            guard let self, case .loaded(let product) = viewModel.state else { return }
            onEnquire?(product)
        }
        viewModel.onChange = { [weak self] in
            guard let self else { return }
            detailView.render(viewModel.state)
        }
        reload()
    }

    private func reload() {
        task?.cancel()
        let model = viewModel
        task = Task { await model.load() }
    }

    deinit { task?.cancel() }
}
