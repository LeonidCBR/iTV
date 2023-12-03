//
//  FavoriteFilterCell.swift
//  iTV
//
//  Created by Яна Латышева on 27.11.2022.
//

import UIKit

/// A view represents the option
class FavoriteFilterCell: UICollectionViewCell {
    // MARK: - Properties

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    var option: FavoriteFilterOption? {
        didSet {
            titleLabel.text = option?.description
        }
    }

    override var isSelected: Bool {
        didSet {
            titleLabel.textColor = isSelected ? .white : .lightGray
            titleLabel.font = isSelected ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 14)

        }
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = bgColor // K.bgColor
        addSubview(titleLabel)
        titleLabel.anchor(centerX: self.centerXAnchor,
                          centerY: self.centerYAnchor)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
