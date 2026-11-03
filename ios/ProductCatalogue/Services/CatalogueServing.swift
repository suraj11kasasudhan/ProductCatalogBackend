import Foundation

protocol CatalogueServing {
    func featured() async throws -> [Product]
    func categories() async throws -> [String]
    func search(query: String) async throws -> [Product]
    func category(_ name: String) async throws -> [ProductSection]
    func product(id: Int) async throws -> Product
    func enquire(_ enquiry: EnquiryRequest) async throws -> Confirmation
}

