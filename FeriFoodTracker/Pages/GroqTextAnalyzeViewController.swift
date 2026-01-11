//
//  GroqTextAnalyzeViewController.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 11. 1. 26.
//

import UIKit

/// Present inside a UINavigationController.
/// - Has: close button, instructions label, text field, bottom rounded "Analyse" button.
/// - On Analyse: dismisses itself first, then calls `completion(nil)`.
final class GroqTextAnalyzeViewController: UIViewController, UITextViewDelegate {

    // MARK: Public
    public let completion: (APIManager.FoodData?) -> Void

    // MARK: UI
    private let instructionsLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .left
        l.font = .preferredFont(forTextStyle: .body)
        l.textColor = .secondaryLabel
        l.text = "Describe your meal (e.g., “2 scrambled eggs with toast”). Tap Analyse to estimate calories and macros."
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let textField: UITextView = {
        let tv = UITextView()
        tv.font = .preferredFont(forTextStyle: .body)
        tv.textColor = .label
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.autocapitalizationType = .sentences
        tv.autocorrectionType = .yes
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let bottomContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: Init
    init(completion: @escaping (APIManager.FoodData?) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Analyze Food"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        textField.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .prominent, target: self, action: #selector(analyseTapped))

        layout()
    }

    // MARK: Layout
    private func layout() {
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        view.addSubview(bottomContainer)

        content.addSubview(instructionsLabel)
        content.addSubview(textField)

        NSLayoutConstraint.activate([
            // Content area
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            instructionsLabel.topAnchor.constraint(equalTo: content.topAnchor),
            instructionsLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            instructionsLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor),

            textField.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 14),
            textField.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
    }

    // MARK: Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func analyseTapped() {
        view.endEditing(true)
        
        guard let text = self.textField.text, !text.isEmpty else {
            self.closeTapped()
            return
        }

        // Per your requirement: dismiss first, then call completion(nil).
        APIManager.shared.fetchFoodDataFromGroqText(prompt: text) { data in
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.completion(data)
                }
            }
        }
    }
}
