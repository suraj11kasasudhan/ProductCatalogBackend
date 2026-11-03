import Foundation

@MainActor
final class ProductDetailViewModel {
    private let api: CatalogueServing
    private let productID: Int
    private(set) var state: LoadState<Product> = .idle { didSet { onChange?() } }
    private var loadID = UUID()
    var onChange: (() -> Void)?

    init(productID: Int, api: CatalogueServing) {
        self.productID = productID
        self.api = api
    }

    func load() async {
        let requestID = UUID()
        loadID = requestID
        guard !Task.isCancelled else { return }
        state = .loading
        do {
            let product = try await api.product(id: productID)
            guard loadID == requestID, !Task.isCancelled else { return }
            state = .loaded(product)
        } catch {
            guard loadID == requestID, !Task.isCancelled, !(error is CancellationError) else { return }
            state = .failed(error.localizedDescription)
        }
    }
}
