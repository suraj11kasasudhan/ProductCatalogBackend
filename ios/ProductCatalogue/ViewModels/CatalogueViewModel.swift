import Foundation

@MainActor
final class CatalogueViewModel {
    let mode: CatalogueMode
    private let api: CatalogueServing
    private(set) var state: LoadState<CatalogueContent> = .idle {
        didSet { onChange?() }
    }
    private var loadID = UUID()
    var onChange: (() -> Void)?

    init(mode: CatalogueMode, api: CatalogueServing) {
        self.mode = mode
        self.api = api
    }

    func load(query: String = "") async {
        let requestID = UUID()
        loadID = requestID
        guard !Task.isCancelled else { return }
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode.isSearch && term.isEmpty {
            state = .loaded(CatalogueContent(categories: [], sections: []))
            return
        }
        state = .loading
        do {
            let content = try await fetchContent(query: term)
            guard loadID == requestID, !Task.isCancelled else { return }
            state = .loaded(content)
        } catch {
            guard loadID == requestID, !Task.isCancelled, !(error is CancellationError) else { return }
            state = .failed(error.localizedDescription)
        }
    }

    private func fetchContent(query: String) async throws -> CatalogueContent {
        switch mode {
        case .home:
            async let products = api.featured()
            async let categories = api.categories()
            let (loadedProducts, loadedCategories) = try await (products, categories)
            return CatalogueContent(categories: loadedCategories, sections: [ProductSection(title: "Featured products", products: loadedProducts)])
        case .category(let name):
            let sections = try await api.category(name)
            return CatalogueContent(categories: [], sections: sections)
        case .search:
            let products = try await api.search(query: query)
            return CatalogueContent(categories: [], sections: [ProductSection(title: "Results", products: products)])
        }
    }
}
