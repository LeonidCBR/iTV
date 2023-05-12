//
//  TestingRootViewController.swift
//  iTVTests
//
//  Created by Яна Латышева on 17.12.2022.
//

import UIKit

class TestingRootViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 25.0)
        label.numberOfLines = 0
        label.text = "Running Integration Unit Tests..."
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        view.backgroundColor = .red
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

}
