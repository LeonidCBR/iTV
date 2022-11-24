//
//  ChannelCell.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import UIKit

protocol ChannelCellDelegate: AnyObject {
    func favoriteChanged(cell: UITableViewCell, channelId: Int, isFavorite: Bool)
}

class ChannelCell: UITableViewCell {

    // MARK: - Properties

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let logoImage: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .lightGray
        return iv
    }()

    private lazy var favoriteButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "star_blue"), for: .selected)
        btn.setImage(UIImage(named: "star"), for: .normal)
        btn.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        return btn
    }()

    private var channelID: Int?

    weak var delegate: ChannelCellDelegate?


    // MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }


    // MARK: - Methods

    private func configureUI() {
//        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(logoImage)
        logoImage.anchor(leading: contentView.leadingAnchor, paddingLeading: 8,
                         width: 60.0,
                         height: 60.0,
                         centerY: contentView.centerYAnchor)
        logoImage.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor,
                                       constant: 8.0).isActive = true
        logoImage.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                          constant: -8.0).isActive = true


        contentView.addSubview(nameLabel)
        nameLabel.anchor(top: contentView.topAnchor, paddingTop: 12.0,
                         leading: logoImage.trailingAnchor, paddingLeading: 16.0)

        contentView.addSubview(titleLabel)
        titleLabel.anchor(top: nameLabel.bottomAnchor, paddingTop: 12.0,
                          leading: logoImage.trailingAnchor, paddingLeading: 16.0)
        titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                           constant: -12.0).isActive = true

        contentView.addSubview(favoriteButton)
        favoriteButton.anchor(trailing: contentView.trailingAnchor, paddingTrailing: 16,
                         width: 24,
                         height: 24,
                         centerY: contentView.centerYAnchor)

        nameLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor,
                                            constant: -16.0).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor,
                                             constant: -16.0).isActive = true
    }

    func setChannel(to channel: Channel) {
        channelID = channel.id
        nameLabel.text = channel.name
        titleLabel.text = channel.title
        favoriteButton.isSelected = channel.isFavorite
    }

    func clearLogoImage() {
        logoImage.image = nil
        logoImage.backgroundColor = .lightGray
    }

    func setLogoImage(to image: UIImage) {
        logoImage.image = image
        logoImage.backgroundColor = .white
    }


    // MARK: - Selectors

    @objc private func favoriteButtonTapped() {
        guard let id = channelID else {
            print("DEBUG: There is no ID!")
            return
        }
        favoriteButton.isSelected = !favoriteButton.isSelected
        delegate?.favoriteChanged(cell: self, channelId: id, isFavorite: favoriteButton.isSelected)
    }

}
