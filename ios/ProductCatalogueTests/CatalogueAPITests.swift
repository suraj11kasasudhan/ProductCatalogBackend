import XCTest
@testable import ProductCatalogue

final class StubURLProtocol: URLProtocol {
    // This test target runs serially; the handler is installed before each request.
    static var handler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            guard let handler = Self.handler, let url = request.url else { throw APIError.invalidURL }
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

final class CatalogueAPITests: XCTestCase {
    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    private func makeAPI() -> CatalogueAPI {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return CatalogueAPI(baseURL: URL(string: "http://localhost:3000/api/")!, session: URLSession(configuration: config))
    }

    func testFeaturedUsesBackendAndDecodesProductContract() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/products/featured")
            XCTAssertEqual(request.httpMethod, "GET")
            return (200, Data("{\"products\":[\(productJSON)]}".utf8))
        }
        let products = try await makeAPI().featured()
        XCTAssertEqual(products.first?.imageUrl.absoluteString, "https://example.test/shirt.png")
        XCTAssertEqual(products.first?.rating.value, 4.5)
    }

    func testSearchEncodesQueryWithoutCreatingExtraParameters() async throws {
        StubURLProtocol.handler = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            XCTAssertEqual(components?.queryItems, [URLQueryItem(name: "q", value: "shirt & gold")])
            return (200, Data(#"{"products":[]}"#.utf8))
        }
        _ = try await makeAPI().search(query: "shirt & gold")
    }

    func testCategoryNameIsOneEncodedPathComponentAndGroupsStaySeparate() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertTrue(request.url!.absoluteString.contains("men%27s%20clothing"))
            XCTAssertTrue(request.url!.absoluteString.hasSuffix("/products"))
            return (200, Data("{\"featured\":[\(productJSON)],\"products\":[]}".utf8))
        }
        let groups = try await makeAPI().category("men's clothing")
        XCTAssertEqual(groups.map(\.title), ["Featured"])
    }

    func testBackendErrorIsSurfacedWithoutShowingSuccess() async {
        StubURLProtocol.handler = { _ in
            (502, Data(#"{"error":{"code":"EMAIL_UNAVAILABLE","message":"Please try again."}}"#.utf8))
        }
        do {
            _ = try await makeAPI().enquire(EnquiryRequest(productId: 1, name: "Customer", email: "c@example.test", phone: nil, message: "Hello"))
            XCTFail("Expected error")
        } catch APIError.rejected(let status, let message) {
            XCTAssertEqual(status, 502)
            XCTAssertEqual(message, "Please try again.")
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testEnquiryPostsJSONToBackend() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/enquiries")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            // URLSession may convert httpBody into httpBodyStream; both are valid.
            var body = request.httpBody
            if body == nil, let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var data = Data()
                let capacity = 1024
                var buffer = [UInt8](repeating: 0, count: capacity)
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: capacity)
                    if count <= 0 { break }
                    data.append(contentsOf: buffer.prefix(count))
                }
                body = data
            }
            let json = try JSONSerialization.jsonObject(with: body!) as! [String: Any]
            XCTAssertEqual(json["productId"] as? Int, 1)
            XCTAssertNil(json["phone"])
            return (200, Data(#"{"message":"Thank you."}"#.utf8))
        }
        let confirmation = try await makeAPI().enquire(EnquiryRequest(productId: 1, name: "Customer", email: "c@example.test", phone: nil, message: "Hello"))
        XCTAssertEqual(confirmation.message, "Thank you.")
    }

    func testMalformedSuccessfulResponseIsRejected() async {
        StubURLProtocol.handler = { _ in (200, Data(#"{"products":[{"wrong":"schema"}]}"#.utf8)) }
        do {
            _ = try await makeAPI().featured()
            XCTFail("Expected schema error")
        } catch APIError.invalidData { }
        catch { XCTFail("Unexpected error: \(error)") }
    }
}
