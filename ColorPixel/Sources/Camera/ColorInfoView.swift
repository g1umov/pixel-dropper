//
//  ColorInfoView.swift
//  ColorPixel
//
//  Created by Vladislav on 30.06.23.
//

import UIKit

final class ColorInfoView: UIView {

    // MARK: Subviews

    private let colorView = UIView().apply {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.white.cgColor
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.backgroundColor = .black
    }

    private let colorNameLabel = UILabel().apply {
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .white
        $0.text = "Unknown"
        $0.lineBreakMode = .byWordWrapping
    }

    // MARK: Constraints

    private lazy var widthConstraint: NSLayoutConstraint = {
        widthAnchor.constraint(equalToConstant: 190)
    }()

    private lazy var colorViewWidth: NSLayoutConstraint = {
        colorView.widthAnchor.constraint(equalToConstant: 34)
    }()

    // MARK: State

    var text: String? {
        get {
            colorNameLabel.text
        }
        set {
            colorNameLabel.text = newValue
        }
    }

    var color: UIColor? {
        get {
            colorView.backgroundColor
        }
        set {
            colorView.backgroundColor = newValue
        }
    }

    var size: CGFloat = 0 {
        didSet {
            colorViewWidth.constant = 34 + (50 * size)
            colorView.layer.cornerRadius = 8 + (11.8 * size)

            let margin = 6 + (8.8 * size)
            layoutMargins = .init(top: margin, left: margin, bottom: margin, right: margin)
            layer.cornerRadius = 8 + (4 * size)

            widthConstraint.constant = 190 + (280 * size)
            colorNameLabel.font = UIFont.systemFont(ofSize: 16 + (24 * size), weight: .medium)
        }
    }

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Setup

private extension ColorInfoView {

    func setupView() {
        setupViewAppearance()
        setupViewLayout()
    }

    func setupViewAppearance() {
        backgroundColor = .black.withAlphaComponent(0.8)
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }

    func setupViewLayout() {
        addSubview(colorView)
        addSubview(colorNameLabel)

        layoutMargins = .init(top: 6, left: 6, bottom: 6, right: 6)

        translatesAutoresizingMaskIntoConstraints = false
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorNameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            colorViewWidth,
            colorView.heightAnchor.constraint(equalTo: colorView.widthAnchor),
            colorView.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            colorView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),

            colorNameLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            colorNameLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 12),
            colorNameLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            colorNameLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            widthConstraint
        ])
    }
}
