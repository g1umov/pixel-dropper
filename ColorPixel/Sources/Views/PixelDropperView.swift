//
//  ColorLabel.swift
//  ColorPixel
//
//  Created by Vladislav on 30.06.23.
//

import UIKit

final class PixelDropperView: UIView {

    private(set) lazy var colorView: UIView = {
        let view = UIView()

        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.backgroundColor = .black

        return view
    }()

    private(set) lazy var textLabel: UILabel = {
        let label = UILabel()

        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.text = "Unknown"
        label.lineBreakMode = .byWordWrapping

        return label
    }()

    private lazy var widthConstraint: NSLayoutConstraint = {
        widthAnchor.constraint(equalToConstant: 190)
    }()

    private lazy var colorViewWidth: NSLayoutConstraint = {
        colorView.widthAnchor.constraint(equalToConstant: 34)
    }()

    var text: String? {
        get {
            textLabel.text
        }
        set {
            textLabel.text = newValue
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

    var poiner: CGPoint {
        .init(x: frame.origin.x + 17 + 6,
              y: frame.origin.y + 17 + 6)
    }

    var selfSize: CGFloat {
        get {
            widthConstraint.constant
        }

        set {
            widthConstraint.constant = newValue
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
            textLabel.font = UIFont.systemFont(ofSize: 16 + (24 * size), weight: .medium)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .black.withAlphaComponent(0.8)
        layer.cornerRadius = 8
        layer.masksToBounds = true

        addSubview(colorView)
        addSubview(textLabel)

        layoutMargins = .init(top: 6, left: 6, bottom: 6, right: 6)

        translatesAutoresizingMaskIntoConstraints = false
        colorView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            colorViewWidth,
            colorView.heightAnchor.constraint(equalTo: colorView.widthAnchor),
            colorView.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            colorView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),

            textLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            widthConstraint
        ])
    }
}
