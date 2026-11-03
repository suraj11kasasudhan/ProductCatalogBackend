import Foundation
@testable import ProductCatalogue

let productJSON = #"{"id":1,"title":"Cotton shirt","description":"Soft cotton","price":12.5,"imageUrl":"https://example.test/shirt.png","category":"men's clothing","rating":{"value":4.5,"count":12}}"#

func sampleProduct() throws -> Product {
    try JSONDecoder().decode(Product.self, from: Data(productJSON.utf8))
}

final class StubCatalogueAPI: CatalogueServing {
    var products: [Product] = []
    var categoryNames = ["men's clothing"]
    var failure: Error?
    var confirmation = Confirmation(message: "Thank you. Your enquiry has been sent.")
    var searchTerms: [String] = []
    var submissions: [EnquiryRequest] = []

    func featured() async throws -> [Product] {
        if let failure { throw failure }
        return products
    }
    func categories() async throws -> [String] {
        if let failure { throw failure }
        return categoryNames
    }
    func search(query: String) async throws -> [Product] {
        searchTerms.append(query)
        if let failure { throw failure }
        return products
    }
    func category(_ name: String) async throws -> [ProductSection] {
        if let failure { throw failure }
        return [ProductSection(title: "Featured", products: products)]
    }
    func product(id: Int) async throws -> Product {
        if let failure { throw failure }
        guard let product = products.first(where: { $0.id == id }) else {
            throw APIError.rejected(status: 404, message: "Product not found.")
        }
        return product
    }
    func enquire(_ enquiry: EnquiryRequest) async throws -> Confirmation {
        submissions.append(enquiry)
        if let failure { throw failure }
        return confirmation
    }
}
