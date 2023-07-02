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

        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 24).isActive = true
        view.heightAnchor.constraint(equalToConstant: 24).isActive = true

        return view
    }()

    private(set) lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = "Unknown"

        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            colorView, textLabel
        ])

        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: 12, left: 12, bottom: 12, right: 12)

        return stackView
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

        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        ])
    }
}
