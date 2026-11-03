import XCTest
@testable import ProductCatalogue

final class ViewModelTests: XCTestCase {
    @MainActor
    func testHomeLoadsFeaturedProductsAndCategories() async throws {
        let api = StubCatalogueAPI()
        api.products = [try sampleProduct()]
        let model = CatalogueViewModel(mode: .home, api: api)
        await model.load()
        guard case .loaded(let content) = model.state else { return XCTFail("Expected loaded home") }
        XCTAssertEqual(content.categories, api.categoryNames)
        XCTAssertEqual(content.sections.first?.products, api.products)
    }

    @MainActor
    func testSearchTrimsTermAndEmptySearchMakesNoRequest() async throws {
        let api = StubCatalogueAPI()
        api.products = [try sampleProduct()]
        let model = CatalogueViewModel(mode: .search, api: api)
        await model.load(query: "   ")
        XCTAssertTrue(api.searchTerms.isEmpty)
        await model.load(query: " cotton ")
        XCTAssertEqual(api.searchTerms, ["cotton"])
        guard case .loaded(let content) = model.state else { return XCTFail("Expected results") }
        XCTAssertEqual(content.sections.first?.products.count, 1)
    }

    @MainActor
    func testSourceFailureBecomesRetryableScreenState() async {
        let api = StubCatalogueAPI()
        api.failure = APIError.rejected(status: 502, message: "Catalogue unavailable.")
        let model = CatalogueViewModel(mode: .home, api: api)
        await model.load()
        guard case .failed(let message) = model.state else { return XCTFail("Expected failure") }
        XCTAssertEqual(message, "Catalogue unavailable.")
        api.failure = nil
        await model.load()
        guard case .loaded = model.state else { return XCTFail("Retry should succeed") }
    }

    @MainActor
    func testProductDetailsFetchByID() async throws {
        let api = StubCatalogueAPI()
        api.products = [try sampleProduct()]
        let model = ProductDetailViewModel(productID: 1, api: api)
        await model.load()
        guard case .loaded(let product) = model.state else { return XCTFail("Expected details") }
        XCTAssertEqual(product.id, 1)
    }

    @MainActor
    func testInvalidEnquiryDoesNotCallBackend() async throws {
        let api = StubCatalogueAPI()
        let model = EnquiryViewModel(product: try sampleProduct(), api: api)
        await model.submit(EnquiryDraft(name: "Customer", email: "bad", message: "Hello"))
        XCTAssertTrue(api.submissions.isEmpty)
        guard case .failed = model.state else { return XCTFail("Expected validation message") }
    }

    @MainActor
    func testEnquiryConfirmsOnlyAfterBackendSuccessAndDoesNotResend() async throws {
        let api = StubCatalogueAPI()
        let model = EnquiryViewModel(product: try sampleProduct(), api: api)
        let draft = EnquiryDraft(name: " Customer ", email: "customer@example.test", phone: " ", message: " Hello ")
        await model.submit(draft)
        guard case .sent(let message) = model.state else { return XCTFail("Expected confirmation") }
        XCTAssertEqual(message, api.confirmation.message)
        XCTAssertEqual(api.submissions.first?.name, "Customer")
        XCTAssertNil(api.submissions.first?.phone)
        await model.submit(draft)
        XCTAssertEqual(api.submissions.count, 1)
    }

    @MainActor
    func testEmailFailureKeepsEnquiryRetryable() async throws {
        let api = StubCatalogueAPI()
        api.failure = APIError.rejected(status: 502, message: "Email could not be sent.")
        let model = EnquiryViewModel(product: try sampleProduct(), api: api)
        let draft = EnquiryDraft(name: "Customer", email: "customer@example.test", message: "Hello")
        await model.submit(draft)
        guard case .failed = model.state else { return XCTFail("Do not thank customer after failure") }
        api.failure = nil
        await model.submit(draft)
        guard case .sent = model.state else { return XCTFail("Retry should succeed") }
    }

    @MainActor
    func testOlderSearchCannotOverwriteNewerSearch() async {
        let api = StubCatalogueAPI()
        let started = expectation(description: "First search started")
        var pending: CheckedContinuation<[Product], Error>?
        api.searchHandler = { query in
            if query == "old" {
                return try await withCheckedThrowingContinuation { continuation in
                    pending = continuation
                    started.fulfill()
                }
            }
            return []
        }
        let model = CatalogueViewModel(mode: .search, api: api)
        let first = Task { await model.load(query: "old") }
        await fulfillment(of: [started], timeout: 1)
        await model.load(query: "new")
        pending?.resume(throwing: APIError.unavailable)
        await first.value
        guard case .loaded(let content) = model.state else {
            return XCTFail("An older failure must not replace the current results")
        }
        XCTAssertTrue(content.sections.first?.products.isEmpty == true)
    }

    func testDraftRejectsInvalidNamePhoneAndMessage() {
        XCTAssertThrowsError(try EnquiryDraft(name: "Two\nLines", email: "c@example.test", message: "Hello").request(productID: 1))
        XCTAssertThrowsError(try EnquiryDraft(name: "Customer", email: "c@example.test", phone: "letters", message: "Hello").request(productID: 1))
        XCTAssertThrowsError(try EnquiryDraft(name: "Customer", email: "c@example.test", message: " ").request(productID: 1))
    }
}
