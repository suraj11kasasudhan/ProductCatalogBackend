import Foundation

final class CatalogueAPI: CatalogueServing {
    private struct ProductsResponse: Decodable { let products: [Product] }
    private struct CategoriesResponse: Decodable { let categories: [String] }
    private struct ProductResponse: Decodable { let product: Product }
    private struct CategoryResponse: Decodable { let featured: [Product]; let products: [Product] }
    private let network: NetworkManaging

    init(network: NetworkManaging) {
        self.network = network
    }

    convenience init(baseURL: URL, session: URLSession? = nil) {
        self.init(network: NetworkManager(baseURL: baseURL, session: session))
    }

    func featured() async throws -> [Product] {
        let response: ProductsResponse = try await send(.featured)
        return response.products
    }

    func categories() async throws -> [String] {
        let response: CategoriesResponse = try await send(.categories)
        return response.categories
    }

    func search(query: String) async throws -> [Product] {
        let response: ProductsResponse = try await send(.search(query))
        return response.products
    }

    func category(_ name: String) async throws -> [ProductSection] {
        let response: CategoryResponse = try await send(.category(name))
        return [
            ProductSection(title: "Featured", products: response.featured),
            ProductSection(title: "More products", products: response.products),
        ].filter { !$0.products.isEmpty }
    }

    func product(id: Int) async throws -> Product {
        let response: ProductResponse = try await send(.product(id))
        return response.product
    }

    func enquire(_ enquiry: EnquiryRequest) async throws -> Confirmation {
        try await send(.enquiry(enquiry))
    }

    private func send<Response: Decodable>(_ route: CatalogueEndpoint) async throws -> Response {
        try await network.send(route.endpoint())
    }
}
