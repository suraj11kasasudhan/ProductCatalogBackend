import UIKit

/// Composition root for screen dependencies and navigation.
@MainActor
final class CatalogueScreenFactory {
    private let service: CatalogueServing

    init(service: CatalogueServing) { self.service = service }

    func catalogue(mode: CatalogueMode) -> CatalogueViewController {
        let controller = CatalogueViewController(viewModel: CatalogueViewModel(mode: mode, api: service))
        controller.onSelectCategory = { [weak controller, self] category in
            controller?.navigationController?.pushViewController(catalogue(mode: .category(category)), animated: true)
        }
        controller.onSelectProduct = { [weak controller, self] id in
            controller?.navigationController?.pushViewController(detail(productID: id), animated: true)
        }
        return controller
    }

    private func detail(productID: Int) -> ProductDetailViewController {
        let controller = ProductDetailViewController(viewModel: ProductDetailViewModel(productID: productID, api: service))
        controller.onEnquire = { [weak controller, self] product in
            let enquiry = EnquiryViewController(viewModel: EnquiryViewModel(product: product, api: service))
            controller?.present(UINavigationController(rootViewController: enquiry), animated: true)
        }
        return controller
    }
}
