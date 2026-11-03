import UIKit

final class ProductDetailViewController: UIViewController {
    private let viewModel: ProductDetailViewModel
    var onEnquire: ((Product) -> Void)?
    private let statusView = StatusView()
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let productImage = RemoteImageView()
    private var task: Task<Void, Never>?

    init(viewModel: ProductDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Product details"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        productImage.heightAnchor.constraint(equalToConstant: 240).isActive = true
        stack.axis = .vertical
        stack.spacing = 20
        for child in [scroll, statusView] {
            child.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child)
            NSLayoutConstraint.activate([
                child.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                child.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                child.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                child.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48),
        ])
        statusView.onRetry = { [weak self] in self?.reload() }
        viewModel.onChange = { [weak self] in self?.render() }
        reload()
    }

    private func reload() {
        task?.cancel()
        let model = viewModel
        task = Task { await model.load() }
    }

    private func render() {
        scroll.isHidden = true
        statusView.isHidden = false
        switch viewModel.state {
        case .idle: break
        case .loading: statusView.show(message: "Loading product…", loading: true)
        case .failed(let message): statusView.show(message: message, canRetry: true)
        case .loaded(let product):
            scroll.isHidden = false
            statusView.isHidden = true
            stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            productImage.contentMode = .scaleAspectFit
            productImage.load(product.imageUrl)
            stack.addArrangedSubview(productImage)
            stack.addArrangedSubview(label(product.title, style: .title2))
            stack.addArrangedSubview(label(product.category.capitalized, style: .subheadline))
            stack.addArrangedSubview(label("Price: \(product.displayPrice)", style: .title3))
            stack.addArrangedSubview(label("Rating: \(product.rating.value.formatted())/5 (\(product.rating.count) reviews)", style: .subheadline))
            stack.addArrangedSubview(label(product.description, style: .body))
            let button = UIButton(type: .system)
            button.configuration = .filled()
            button.setTitle("Enquire about this product", for: .normal)
            button.addTarget(self, action: #selector(enquire), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }

    private func label(_ text: String, style: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    @objc private func enquire() {
        guard case .loaded(let product) = viewModel.state else { return }
        onEnquire?(product)
    }

    deinit { task?.cancel() }
}
