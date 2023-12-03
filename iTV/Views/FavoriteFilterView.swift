//
//  FavoriteFilterView.swift
//  iTV
//
//  Created by Яна Латышева on 27.11.2022.
//

import UIKit

protocol FavoriteFilterViewDelegate: AnyObject {
    func filterValueChanged()
}

/// A view represents filter's options
class FavoriteFilterView: UIView {

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .white
        view.delegate = self
        view.dataSource = self
        view.register(FavoriteFilterCell.self, forCellWithReuseIdentifier: filterCellIdentifier)
        return view
    }()

    private let underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .blue
        return view
    }()

    private var underlineViewLeadingAnchor: NSLayoutConstraint!
    private let optionsCount: CGFloat = CGFloat(FavoriteFilterOption.allCases.count)
    private let filterCellIdentifier = "FavoriteFilterCell"
    weak var delegate: FavoriteFilterViewDelegate?

    private(set) var selectedSegmentIndex: Int = 0 {
        didSet {
            delegate?.filterValueChanged()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        collectionView.anchor(top: topAnchor,
                              bottom: bottomAnchor, paddingBottom: 2,
                              leading: leadingAnchor,
                              trailing: trailingAnchor)

        addSubview(underlineView)
        underlineView.anchor(top: collectionView.bottomAnchor,
                             bottom: bottomAnchor)
        underlineView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/optionsCount).isActive = true

        // Set up constraint for leading anchor
        // this constraint will be using with animation
        underlineViewLeadingAnchor = NSLayoutConstraint(item: underlineView,
                                                        attribute: .leading,
                                                        relatedBy: .equal,
                                                        toItem: self,
                                                        attribute: .leading,
                                                        multiplier: 1,
                                                        constant: 0)
        underlineViewLeadingAnchor.isActive = true

        // Select default segment
        let indexPath = IndexPath(row: selectedSegmentIndex, section: 0)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension FavoriteFilterView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return FavoriteFilterOption.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: filterCellIdentifier,
            for: indexPath) as? FavoriteFilterCell
        else {
            fatalError("Error: Cannot cast to FavoriteFilterCell!")
        }
        cell.option = FavoriteFilterOption(rawValue: indexPath.row)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / optionsCount, height: collectionView.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.underlineViewLeadingAnchor.constant = cell.frame.origin.x
            self.layoutIfNeeded()
        }
        selectedSegmentIndex = indexPath.row
    }
}
