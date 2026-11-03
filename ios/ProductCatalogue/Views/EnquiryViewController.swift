import UIKit

final class EnquiryViewController: UIViewController {
    private let viewModel: EnquiryViewModel
    private let enquiryView: EnquiryView
    private var task: Task<Void, Never>?

    init(viewModel: EnquiryViewModel) {
        self.viewModel = viewModel
        enquiryView = EnquiryView(product: viewModel.product)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }
    override func loadView() { view = enquiryView }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Let’s talk details"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        enquiryView.onSubmit = { [weak self] draft in
            guard let self, task == nil else { return }
            let model = viewModel
            task = Task { [weak self] in
                await model.submit(draft)
                self?.task = nil
            }
        }
        viewModel.onChange = { [weak self] in self?.render() }
        render()
    }

    private func render() {
        let sending = viewModel.isSending
        navigationItem.leftBarButtonItem?.isEnabled = !sending
        isModalInPresentation = sending
        enquiryView.render(sending: sending, completed: viewModel.isSent, error: viewModel.errorMessage)
        if let message = viewModel.errorMessage {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        if case .sent(let message) = viewModel.state {
            let alert = UIAlertController(title: "Thank you", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in self?.dismiss(animated: true) })
            present(alert, animated: true)
        }
    }

    @objc private func close() { dismiss(animated: true) }
    deinit { task?.cancel() }
}
