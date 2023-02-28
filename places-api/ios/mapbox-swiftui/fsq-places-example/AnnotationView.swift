//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import UIKit

final class AnnotationView: UIView {
    var selected: Bool = false {
        didSet {
            selectButton.setTitle(selected ? "Deselect" : "Select", for: .normal)
        }
    }

    var title: String? {
        get { centerLabel.text }
        set { centerLabel.text = newValue }
    }

    lazy var centerLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 0
        return label
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("X", for: .normal)
        return button
    }()

    lazy var selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 0.9882352941, alpha: 1)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.setTitle("Select", for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .darkGray.withAlphaComponent(0.5)
        layer.cornerRadius = 5.0

        centerLabel.numberOfLines = 2
        centerLabel.textAlignment = .center
        centerLabel.textColor = .white
        centerLabel.font = UIFont.boldSystemFont(ofSize: 12)
        centerLabel.preferredMaxLayoutWidth = 100

        [centerLabel, closeButton, selectButton].forEach { item in
            item.translatesAutoresizingMaskIntoConstraints = false
            addSubview(item)
        }

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            centerLabel.heightAnchor.constraint(equalToConstant: 30),
            centerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            centerLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: 0),
            centerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),

            selectButton.topAnchor.constraint(equalTo: centerLabel.bottomAnchor, constant: 4),
            selectButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            selectButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            selectButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
