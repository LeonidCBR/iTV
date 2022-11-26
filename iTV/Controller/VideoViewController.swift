//
//  VideoViewController.swift
//  iTV
//
//  Created by Яна Латышева on 26.11.2022.
//

import UIKit
import AVFoundation

class VideoViewController: UIViewController {

    // MARK: - Properties
    
    let videoView = UIView()
    var videoPlayer: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var channel: CDChannel!

    private lazy var dismissButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "arrow"), for: .normal)
        btn.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var settingsButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "settings"), for: .normal)
        btn.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        return btn
    }()

    private let logoImage: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .clear
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 19.0)
        label.numberOfLines = 0
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.numberOfLines = 0
        return label
    }()


    // MARK: - Lifecycle
    
    init(with channel: CDChannel) {
        self.channel = channel
        nameLabel.text = channel.name
        titleLabel.text = channel.title
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        configurePlayer()
        configureUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPlayer.play()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }


    // MARK: - Methods

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }

    private func configurePlayer() {
        guard let path = channel.url, let mediaUrl = URL(string: path) else {
            videoPlayer = AVPlayer()
            playerLayer = AVPlayerLayer()
            return
        }
        videoPlayer = AVPlayer(url: mediaUrl)
        videoPlayer.preventsDisplaySleepDuringVideoPlayback = true
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer.videoGravity = .resize
        videoView.layer.addSublayer(playerLayer)
    }

    private func configureUI() {
        view.backgroundColor = .black
        view.addSubview(videoView)
        videoView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                         bottom: view.safeAreaLayoutGuide.bottomAnchor,
                         leading: view.safeAreaLayoutGuide.leadingAnchor,
                         trailing: view.safeAreaLayoutGuide.trailingAnchor)

        view.addSubview(dismissButton)
        dismissButton.anchor(leading: view.safeAreaLayoutGuide.leadingAnchor, paddingLeading: 23.0,
                             width: 18,
                             height: 18)

        view.addSubview(settingsButton)
        settingsButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 31.0,
                              trailing: view.safeAreaLayoutGuide.trailingAnchor, paddingTrailing: 19.0,
                              width: 18,
                              height: 18)

        view.addSubview(logoImage)
        logoImage.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 12,
                         leading: dismissButton.trailingAnchor, paddingLeading: 23,
                         width: 44.0,
                         height: 44.0)

        dismissButton.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor).isActive = true

        view.addSubview(titleLabel)
        titleLabel.anchor(top: logoImage.topAnchor,
                          leading: logoImage.trailingAnchor, paddingLeading: 24.0,
                          trailing: view.safeAreaLayoutGuide.trailingAnchor, paddingTrailing: 23.0)

        view.addSubview(nameLabel)
        nameLabel.anchor(top: titleLabel.bottomAnchor, paddingTop: 2.0,
                         leading: titleLabel.leadingAnchor,
                         trailing: titleLabel.trailingAnchor)
    }

    func setLogoImage(to image: UIImage) {
        logoImage.image = image
    }

    // MARK: - Selectors

    @objc private func dismissButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func settingsButtonTapped() {
        print("DEBUG: \(#function)")
    }

}
