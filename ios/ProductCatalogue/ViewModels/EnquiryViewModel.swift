import Foundation

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
