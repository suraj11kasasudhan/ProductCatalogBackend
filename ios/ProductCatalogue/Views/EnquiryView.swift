import UIKit

final class EnquiryView: UIView {
    var onSubmit: ((EnquiryDraft) -> Void)?
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let messageField = UITextView()
    private let submitButton = CatalogueStyle.button("Send enquiry", symbol: "paperplane")
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(product: Product) {
        super.init(frame: .zero)
        backgroundColor = CatalogueStyle.background
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48),
        ])
        let productLabel = CatalogueStyle.label(product.title, style: .title2)
        stack.addArrangedSubview(CatalogueStyle.label("A LITTLE MORE INFORMATION", style: .caption1, color: CatalogueStyle.accent))
        stack.addArrangedSubview(productLabel)
        stack.addArrangedSubview(CatalogueStyle.label("Tell us what you’d like to know. We’ll pass your enquiry to the team.", style: .subheadline, color: .secondaryLabel))
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
        stack.addArrangedSubview(CatalogueStyle.label("Message", style: .subheadline))
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

        submitButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        stack.addArrangedSubview(submitButton)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    private func addField(_ field: UITextField, title: String, to stack: UIStackView) {
        stack.addArrangedSubview(CatalogueStyle.label(title, style: .subheadline))
        field.borderStyle = .roundedRect
        field.backgroundColor = CatalogueStyle.surface
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.accessibilityLabel = title
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        stack.addArrangedSubview(field)
    }

    func render(sending: Bool, completed: Bool, error: String?) {
        submitButton.isEnabled = !sending && !completed
        [nameField, emailField, phoneField].forEach { $0.isEnabled = !sending && !completed }
        messageField.isEditable = !sending && !completed
        sending ? spinner.startAnimating() : spinner.stopAnimating()
        statusLabel.text = error
        statusLabel.isHidden = error == nil
    }

    @objc private func submit() {
        endEditing(true)
        onSubmit?(EnquiryDraft(name: nameField.text ?? "", email: emailField.text ?? "",
            phone: phoneField.text ?? "", message: messageField.text ?? ""))
    }
}
