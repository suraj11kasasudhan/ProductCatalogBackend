import Foundation

enum CatalogueMode {
    case home
    case search
    case category(String)

    var title: String {
        switch self {
        case .home: return "Catalogue"
        case .search: return "Search"
        case .category(let name): return name.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    var isSearch: Bool {
        if case .search = self { return true }
        return false
    }
}
