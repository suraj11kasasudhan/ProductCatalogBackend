import Foundation

/// Backend routes are centralized here; services only map domain responses.
enum CatalogueEndpoint {
    case featured
    case categories
    case search(String)
    case category(String)
    case product(Int)
    case enquiry(EnquiryRequest)

    func endpoint() throws -> APIEndpoint {
        switch self {
        case .featured:
            return APIEndpoint(pathComponents: ["products", "featured"])
        case .categories:
            return APIEndpoint(pathComponents: ["categories"])
        case .search(let query):
            return APIEndpoint(pathComponents: ["products"], query: [URLQueryItem(name: "q", value: query)])
        case .category(let name):
            return APIEndpoint(pathComponents: ["categories", name, "products"])
        case .product(let id):
            return APIEndpoint(pathComponents: ["products", String(id)])
        case .enquiry(let enquiry):
            return APIEndpoint(pathComponents: ["enquiries"], method: .post, body: try JSONEncoder().encode(enquiry))
        }
    }
}
