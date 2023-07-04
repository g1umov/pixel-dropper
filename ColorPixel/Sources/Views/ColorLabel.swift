//
//  ColorLabel.swift
//  ColorPixel
//
//  Created by Vladislav on 30.06.23.
//

import UIKit

final class ColorLabel: UIView {

    private(set) lazy var colorView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        view.backgroundColor = .black

        return view
    }()

    private(set) lazy var textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.text = "Unknown"

        return label
    }()

    private lazy var widthConstraint: NSLayoutConstraint = {
        widthAnchor.constraint(equalToConstant: 180)
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

        layoutMargins = .init(top: 12, left: 12, bottom: 12, right: 12)

        translatesAutoresizingMaskIntoConstraints = false
        colorView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            colorView.widthAnchor.constraint(equalToConstant: 24),
            colorView.heightAnchor.constraint(equalToConstant: 24),
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
