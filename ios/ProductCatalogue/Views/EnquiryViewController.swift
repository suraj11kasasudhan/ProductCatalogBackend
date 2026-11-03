import UIKit

final class EnquiryViewController: UIViewController {
    private let viewModel: EnquiryViewModel
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let messageField = UITextView()
    private let submitButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var task: Task<Void, Never>?

    init(viewModel: EnquiryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Product enquiry"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48),
        ])
        let productLabel = UILabel()
        productLabel.text = viewModel.product.title
        productLabel.font = .preferredFont(forTextStyle: .headline)
        productLabel.adjustsFontForContentSizeCategory = true
        productLabel.numberOfLines = 0
        stack.addArrangedSubview(productLabel)
        addField(nameField, title: "Name", to: stack)
        nameField.textContentType = .name
        addField(emailField, title: "Email", to: stack)
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        addField(phoneField, title: "Phone (optional)", to: stack)
        phoneField.keyboardType = .phonePad
        phoneField.textContentType = .telephoneNumber
        stack.addArrangedSubview(fieldLabel("Message"))
        messageField.backgroundColor = .secondarySystemGroupedBackground
        messageField.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        messageField.font = .preferredFont(forTextStyle: .body)
        messageField.adjustsFontForContentSizeCategory = true
        messageField.accessibilityLabel = "Message"
        messageField.layer.borderWidth = 1
        messageField.layer.borderColor = UIColor.separator.cgColor
        messageField.layer.cornerRadius = 8
        messageField.heightAnchor.constraint(equalToConstant: 160).isActive = true
        stack.addArrangedSubview(messageField)
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .systemRed
        statusLabel.numberOfLines = 0
        stack.addArrangedSubview(statusLabel)
        spinner.accessibilityLabel = "Sending enquiry"
        stack.addArrangedSubview(spinner)
        submitButton.configuration = .filled()
        submitButton.configuration?.cornerStyle = .capsule
        submitButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        submitButton.setTitle("Send enquiry", for: .normal)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        stack.addArrangedSubview(submitButton)
        viewModel.onChange = { [weak self] in self?.render() }
        render()
    }

    private func fieldLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func addField(_ field: UITextField, title: String, to stack: UIStackView) {
        stack.addArrangedSubview(fieldLabel(title))
        field.borderStyle = .roundedRect
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.accessibilityLabel = title
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        stack.addArrangedSubview(field)
    }

    private func render() {
        let sending: Bool
        let completed: Bool
        switch viewModel.state {
        case .sending: sending = true; completed = false
        case .sent: sending = false; completed = true
        default: sending = false; completed = false
        }
        submitButton.isEnabled = !sending && !completed
        navigationItem.leftBarButtonItem?.isEnabled = !sending
        isModalInPresentation = sending
        [nameField, emailField, phoneField].forEach { $0.isEnabled = !sending && !completed }
        messageField.isEditable = !sending && !completed
        sending ? spinner.startAnimating() : spinner.stopAnimating()
        statusLabel.text = nil
        if case .failed(let message) = viewModel.state {
            statusLabel.text = message
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        if case .sent(let message) = viewModel.state {
            let alert = UIAlertController(title: "Thank you", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in self?.dismiss(animated: true) })
            present(alert, animated: true)
        }
    }

    @objc private func submit() {
        view.endEditing(true)
        let draft = EnquiryDraft(name: nameField.text ?? "", email: emailField.text ?? "", phone: phoneField.text ?? "", message: messageField.text ?? "")
        let model = viewModel
        task = Task { await model.submit(draft) }
    }

    @objc private func close() { dismiss(animated: true) }
    deinit { task?.cancel() }
}
