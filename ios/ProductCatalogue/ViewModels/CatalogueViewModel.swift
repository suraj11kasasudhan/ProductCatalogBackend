import Foundation

enum CatalogueMode {
    case home
    case search
    case category(String)

    var title: String {
        switch self {
        case .home: return "Catalogue"
        case .search: return "Search"
        case .category(let name): return name.capitalized
        }
    }

    var isSearch: Bool {
        if case .search = self { return true }
        return false
    }
}

@MainActor
final class CatalogueViewModel {
    let mode: CatalogueMode
    private let api: CatalogueServing
    private(set) var state: LoadState<CatalogueContent> = .idle {
        didSet { onChange?() }
    }
    var onChange: (() -> Void)?

    init(mode: CatalogueMode, api: CatalogueServing) {
        self.mode = mode
        self.api = api
    }

    func load(query: String = "") async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode.isSearch && term.isEmpty {
            state = .loaded(CatalogueContent(categories: [], sections: []))
            return
        }
        state = .loading
        do {
            let content: CatalogueContent
            switch mode {
            case .home:
                async let products = api.featured()
                async let categories = api.categories()
                let (loadedProducts, loadedCategories) = try await (products, categories)
                content = CatalogueContent(categories: loadedCategories, sections: [ProductSection(title: "Featured products", products: loadedProducts)])
            case .category(let name):
                let sections = try await api.category(name)
                content = CatalogueContent(categories: [], sections: sections)
            case .search:
                let products = try await api.search(query: term)
                content = CatalogueContent(categories: [], sections: [ProductSection(title: "Results", products: products)])
            }
            guard !Task.isCancelled else { return }
            state = .loaded(content)
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            state = .failed(error.localizedDescription)
        }
    }
}
