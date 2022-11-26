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
        btn.setTitle("Back", for: .normal)
//        btn.setImage(UIImage(named: "arrow"), for: .normal)
        btn.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        return btn
    }()


    // MARK: - Lifecycle
    
    init(with channel: CDChannel) {
        self.channel = channel
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
        playerLayer.videoGravity = .resize // .resizeAspect
        videoView.layer.addSublayer(playerLayer)
    }

    private func configureUI() {
        view.addSubview(videoView)
        videoView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                         bottom: view.safeAreaLayoutGuide.bottomAnchor,
                         leading: view.safeAreaLayoutGuide.leadingAnchor,
                         trailing: view.safeAreaLayoutGuide.trailingAnchor)

        view.addSubview(dismissButton)
        dismissButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 20,
                             leading: view.safeAreaLayoutGuide.leadingAnchor, paddingLeading: 23) //, //width: 18, height: 18)
    }


    // MARK: - Selectors

    @objc private func dismissButtonTapped() {
        dismiss(animated: true)
    }

}
