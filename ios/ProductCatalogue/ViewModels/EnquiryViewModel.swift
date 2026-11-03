import Foundation

struct EnquiryDraft {
    var name = ""
    var email = ""
    var phone = ""
    var message = ""

    func request(productID: Int) throws -> EnquiryRequest {
        let name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = self.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = self.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = self.message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...100).contains(name.count), name.rangeOfCharacter(from: .newlines) == nil else {
            throw FormError.invalid("Enter your name using one line (up to 100 characters).")
        }
        guard email.count <= 254, email.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil else {
            throw FormError.invalid("Enter a valid email address.")
        }
        guard phone.isEmpty || ((3...30).contains(phone.count) && phone.range(of: #"^[+()\d .-]+$"#, options: .regularExpression) != nil) else {
            throw FormError.invalid("Enter a valid phone number, or leave it empty.")
        }
        guard (1...5000).contains(message.count) else {
            throw FormError.invalid("Enter a message (up to 5,000 characters).")
        }
        return EnquiryRequest(productId: productID, name: name, email: email, phone: phone.isEmpty ? nil : phone, message: message)
    }
}

enum FormError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

@MainActor
final class EnquiryViewModel {
    enum State {
        case editing
        case sending
        case sent(String)
        case failed(String)
    }

    let product: Product
    private let api: CatalogueServing
    private(set) var state: State = .editing { didSet { onChange?() } }
    var onChange: (() -> Void)?

    init(product: Product, api: CatalogueServing) {
        self.product = product
        self.api = api
    }

    func submit(_ draft: EnquiryDraft) async {
        // Keep duplicate taps from producing duplicate emails within this screen.
        switch state {
        case .sending, .sent: return
        case .editing, .failed: break
        }
        do {
            let request = try draft.request(productID: product.id)
            state = .sending
            let confirmation = try await api.enquire(request)
            guard !Task.isCancelled else { return }
            state = .sent(confirmation.message)
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            state = .failed(error.localizedDescription)
        }
    }
}
