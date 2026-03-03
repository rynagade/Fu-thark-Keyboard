//
//  KeyboardViewController.swift
//  Fúthark Keyboard
//
//  Created by Rynagade on 10/28/23.
//

import UIKit

final class KeyboardViewController: UIInputViewController, UIInputViewAudioFeedback {

    var enableInputClicksWhenVisible: Bool { true }

    private struct RuneKey {
        let codePoint: UInt32
        let transliteration: String
        let name: String

        var rune: String {
            guard let scalar = UnicodeScalar(codePoint) else {
                assertionFailure("Invalid rune scalar: \(codePoint)")
                return ""
            }

            return String(scalar)
        }
    }

    private enum RuneAlphabet: Int, CaseIterable {
        case elder
        case younger

        var title: String {
            switch self {
            case .elder:
                return "Elder"
            case .younger:
                return "Younger"
            }
        }

        var rows: [[RuneKey]] {
            switch self {
            case .elder:
                return [
                    [
                        RuneKey(codePoint: 0x16A0, transliteration: "F", name: "Fehu"),
                        RuneKey(codePoint: 0x16A2, transliteration: "U", name: "Uruz"),
                        RuneKey(codePoint: 0x16A6, transliteration: "TH", name: "Thurisaz"),
                        RuneKey(codePoint: 0x16A8, transliteration: "A", name: "Ansuz"),
                        RuneKey(codePoint: 0x16B1, transliteration: "R", name: "Raido"),
                        RuneKey(codePoint: 0x16B2, transliteration: "K", name: "Kauna"),
                        RuneKey(codePoint: 0x16B7, transliteration: "G", name: "Gebo"),
                        RuneKey(codePoint: 0x16B9, transliteration: "W", name: "Wunjo")
                    ],
                    [
                        RuneKey(codePoint: 0x16BA, transliteration: "H", name: "Hagalaz"),
                        RuneKey(codePoint: 0x16BE, transliteration: "N", name: "Naudiz"),
                        RuneKey(codePoint: 0x16C1, transliteration: "I", name: "Isaz"),
                        RuneKey(codePoint: 0x16C3, transliteration: "J", name: "Jera"),
                        RuneKey(codePoint: 0x16C7, transliteration: "EI", name: "Eihwaz"),
                        RuneKey(codePoint: 0x16C8, transliteration: "P", name: "Pertho"),
                        RuneKey(codePoint: 0x16C9, transliteration: "Z", name: "Algiz"),
                        RuneKey(codePoint: 0x16CA, transliteration: "S", name: "Sowilo")
                    ],
                    [
                        RuneKey(codePoint: 0x16CF, transliteration: "T", name: "Tiwaz"),
                        RuneKey(codePoint: 0x16D2, transliteration: "B", name: "Berkano"),
                        RuneKey(codePoint: 0x16D6, transliteration: "E", name: "Ehwaz"),
                        RuneKey(codePoint: 0x16D7, transliteration: "M", name: "Mannaz"),
                        RuneKey(codePoint: 0x16DA, transliteration: "L", name: "Laguz"),
                        RuneKey(codePoint: 0x16DC, transliteration: "NG", name: "Ingwaz"),
                        RuneKey(codePoint: 0x16DE, transliteration: "D", name: "Dagaz"),
                        RuneKey(codePoint: 0x16DF, transliteration: "O", name: "Othala")
                    ]
                ]

            case .younger:
                return [
                    [
                        RuneKey(codePoint: 0x16A0, transliteration: "F/V", name: "Fe"),
                        RuneKey(codePoint: 0x16A2, transliteration: "U/O", name: "Ur"),
                        RuneKey(codePoint: 0x16A6, transliteration: "TH/D", name: "Thurs"),
                        RuneKey(codePoint: 0x16AC, transliteration: "O", name: "Oss"),
                        RuneKey(codePoint: 0x16B1, transliteration: "R", name: "Reid"),
                        RuneKey(codePoint: 0x16B4, transliteration: "K/G", name: "Kaun")
                    ],
                    [
                        RuneKey(codePoint: 0x16BC, transliteration: "H", name: "Hagall"),
                        RuneKey(codePoint: 0x16BE, transliteration: "N", name: "Naudr"),
                        RuneKey(codePoint: 0x16C1, transliteration: "I/E", name: "Iss"),
                        RuneKey(codePoint: 0x16C5, transliteration: "A", name: "Ar"),
                        RuneKey(codePoint: 0x16CB, transliteration: "S", name: "Sol")
                    ],
                    [
                        RuneKey(codePoint: 0x16CF, transliteration: "T/D", name: "Tyr"),
                        RuneKey(codePoint: 0x16D2, transliteration: "B/P", name: "Bjarkan"),
                        RuneKey(codePoint: 0x16D8, transliteration: "M", name: "Madr"),
                        RuneKey(codePoint: 0x16DA, transliteration: "L", name: "Logr"),
                        RuneKey(codePoint: 0x16E6, transliteration: "R", name: "Yr")
                    ]
                ]
            }
        }
    }

    private var keyboardHeightConstraint: NSLayoutConstraint?

    private lazy var alphabetControl: UISegmentedControl = {
        let control = UISegmentedControl(items: RuneAlphabet.allCases.map(\.title))
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = RuneAlphabet.elder.rawValue
        control.selectedSegmentTintColor = .systemBlue
        control.backgroundColor = .secondarySystemBackground
        control.addTarget(self, action: #selector(alphabetDidChange(_:)), for: .valueChanged)
        return control
    }()

    private lazy var runeRowsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var nextKeyboardButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        button.accessibilityLabel = NSLocalizedString(
            "Next Keyboard",
            comment: "Title for the button that switches to the next keyboard"
        )

        var configuration = UIButton.Configuration.gray()
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = .tertiarySystemFill
        configuration.baseForegroundColor = .label
        configuration.image = UIImage(systemName: "globe")
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

        button.configuration = configuration
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }()

    private lazy var runeSeparatorButton: UIButton = {
        let button = makeControlButton(title: String(UnicodeScalar(0x16EB)!), action: #selector(insertRuneSeparator))
        button.accessibilityLabel = "Runic punctuation"
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }()

    private lazy var spaceButton: UIButton = {
        let button = makeControlButton(title: "Space", action: #selector(insertSpace))
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }()

    private lazy var deleteButton: UIButton = {
        let button = makeControlButton(title: nil, systemImage: "delete.left", action: #selector(deleteCharacter))
        button.accessibilityLabel = "Delete"
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }()

    private lazy var returnButton: UIButton = {
        let button = makeControlButton(title: "Return", action: #selector(insertReturn))
        button.widthAnchor.constraint(equalToConstant: 84).isActive = true
        return button
    }()

    private lazy var controlsRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            nextKeyboardButton,
            runeSeparatorButton,
            spaceButton,
            deleteButton,
            returnButton
        ])
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [alphabetControl, runeRowsStackView, controlsRow])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var selectedAlphabet: RuneAlphabet {
        RuneAlphabet(rawValue: alphabetControl.selectedSegmentIndex) ?? .elder
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        view.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            alphabetControl.heightAnchor.constraint(equalToConstant: 32),
            controlsRow.heightAnchor.constraint(equalToConstant: 44),

            mainStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])

        reloadRuneRows()
    }

    override func updateViewConstraints() {
        if keyboardHeightConstraint == nil {
            let constraint = view.heightAnchor.constraint(equalToConstant: preferredKeyboardHeight)
            constraint.priority = .required
            constraint.isActive = true
            keyboardHeightConstraint = constraint
        } else {
            keyboardHeightConstraint?.constant = preferredKeyboardHeight
        }

        super.updateViewConstraints()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        keyboardHeightConstraint?.constant = preferredKeyboardHeight
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
    }

    @objc private func alphabetDidChange(_ sender: UISegmentedControl) {
        reloadRuneRows()
    }

    @objc private func insertRuneSeparator() {
        insertText(String(UnicodeScalar(0x16EB)!))
    }

    @objc private func insertSpace() {
        insertText(" ")
    }

    @objc private func insertReturn() {
        insertText("\n")
    }

    @objc private func deleteCharacter() {
        playKeyClick()
        textDocumentProxy.deleteBackward()
    }

    private var preferredKeyboardHeight: CGFloat {
        traitCollection.verticalSizeClass == .compact ? 236 : 272
    }

    private func reloadRuneRows() {
        runeRowsStackView.arrangedSubviews.forEach { subview in
            runeRowsStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        selectedAlphabet.rows.forEach { row in
            runeRowsStackView.addArrangedSubview(makeRuneRow(for: row))
        }
    }

    private func makeRuneRow(for keys: [RuneKey]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 6

        keys.forEach { key in
            row.addArrangedSubview(makeRuneButton(for: key))
        }

        return row
    }

    private func makeRuneButton(for key: RuneKey) -> UIButton {
        let action = UIAction { [weak self] _ in
            self?.insertText(key.rune)
        }

        let button = UIButton(type: .system, primaryAction: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.layer.cornerCurve = .continuous
        button.accessibilityLabel = "\(key.name), \(key.transliteration)"
        button.accessibilityValue = key.rune

        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .secondarySystemBackground
        configuration.baseForegroundColor = .label
        configuration.cornerStyle = .medium
        configuration.title = key.rune
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4)
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
            return outgoing
        }

        button.configuration = configuration
        return button
    }

    private func makeControlButton(
        title: String?,
        systemImage: String? = nil,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)

        var configuration = UIButton.Configuration.gray()
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = .tertiarySystemFill
        configuration.baseForegroundColor = .label
        configuration.title = title
        configuration.image = systemImage.flatMap { UIImage(systemName: $0) }
        configuration.imagePlacement = .leading
        configuration.imagePadding = 4
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return outgoing
        }

        button.configuration = configuration
        return button
    }

    private func insertText(_ text: String) {
        playKeyClick()
        textDocumentProxy.insertText(text)
    }

    private func playKeyClick() {
        UIDevice.current.playInputClick()
    }
}
