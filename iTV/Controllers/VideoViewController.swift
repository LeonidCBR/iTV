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

    private var mediaItems: [MediaItem] = []
    private let videoView = UIView()
    private var videoPlayer: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var channelProperties: ChannelProperties
    private let imageProvider: ImageProvider
    private let qualityCellIdentifier = "qualityCellIdentifier"

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

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.backgroundColor = .lightGray
        table.register(UITableViewCell.self, forCellReuseIdentifier: qualityCellIdentifier)
        table.delegate = self
        table.dataSource = self
        return table
    }()


    // MARK: - Lifecycle

    init(with channelProperties: ChannelProperties, imageProvider: ImageProvider) {
        self.channelProperties = channelProperties
        self.imageProvider = imageProvider
        nameLabel.text = channelProperties.name
        titleLabel.text = channelProperties.title
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        configureUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPlayer.play()


        //fetchMediaItems()

        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }


    // MARK: - Methods

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }

    private func configureUI() {
        view.backgroundColor = .black
        configureVideoView()
        configureDismissButton()
        configureSettingsButton()
        configureLogoImage()
        configureTitleLabel()
        configureNameLabel()
        configureTableView()
        configurePlayer()
    }

    private func configureVideoView() {
        view.addSubview(videoView)
        videoView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                         bottom: view.safeAreaLayoutGuide.bottomAnchor,
                         leading: view.safeAreaLayoutGuide.leadingAnchor,
                         trailing: view.safeAreaLayoutGuide.trailingAnchor)
    }

    private func configureDismissButton() {
        view.addSubview(dismissButton)
        dismissButton.anchor(leading: view.safeAreaLayoutGuide.leadingAnchor,
                             paddingLeading: 23.0,
                             width: 18,
                             height: 18)
    }

    private func configureSettingsButton() {
        view.addSubview(settingsButton)
        settingsButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor,
                              paddingBottom: 31.0,
                              trailing: view.safeAreaLayoutGuide.trailingAnchor,
                              paddingTrailing: 19.0,
                              width: 18,
                              height: 18)
    }

    private func configureLogoImage() {
        view.addSubview(logoImage)
        logoImage.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                         paddingTop: 12,
                         leading: dismissButton.trailingAnchor,
                         paddingLeading: 23,
                         width: 44.0,
                         height: 44.0)
        dismissButton.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor).isActive = true

        guard !channelProperties.image.isEmpty else { return }
        Task {
            let image = try? await imageProvider.fetchImage(withPath: channelProperties.image)
            logoImage.image = image
        }
    }

    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.anchor(top: logoImage.topAnchor,
                          leading: logoImage.trailingAnchor,
                          paddingLeading: 24.0,
                          trailing: view.safeAreaLayoutGuide.trailingAnchor,
                          paddingTrailing: 23.0)
    }

    private func configureNameLabel() {
        view.addSubview(nameLabel)
        nameLabel.anchor(top: titleLabel.bottomAnchor, paddingTop: 2.0,
                         leading: titleLabel.leadingAnchor,
                         trailing: titleLabel.trailingAnchor)
    }

    private func configureTableView() {
        view.addSubview(tableView)
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 100.0,
                    bottom: settingsButton.topAnchor, paddingBottom: 20.0,
                    trailing: view.safeAreaLayoutGuide.trailingAnchor, paddingTrailing: 16.0,
                    width: 100.0)
    }

    private func configurePlayer() {
        guard let mediaUrl = URL(string: channelProperties.url) else {
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
/*
    private func fetchMediaItems() {

        // TODO: - Consider to use it
        // videoPlayer.currentItem?.preferredPeakBitRate

        // TODO: Do the work in the background by passing channelID

        print("DEBUG: Fetch media items in order to get a quality list")
        guard let mediaUrl = URL(string: channelProperties.url) else {
            showErrorMessage("The url \"\(channelProperties.url)\" is not valid.")
            return
        }
        let parser = M3UParser(withUrl: mediaUrl)
        if let mediaItems = try? parser.getMediaItems() {
            self.mediaItems = mediaItems
            print("DEBUG: Got media assets. Count = \(mediaItems.count)")
            tableView.reloadData()
        } else {
            print("DEBUG: Could not fetch media assets.")
        }
    }
*/

//    func setLogoImage(to image: UIImage) {
//        logoImage.image = image
//    }

    
    // MARK: - Selectors

    @objc private func dismissButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func settingsButtonTapped() {
        print("DEBUG: \(#function)")
        tableView.isHidden = !tableView.isHidden
    }

}


// MARK: - UITableViewDataSource, UITableViewDelegate

extension VideoViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mediaItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: qualityCellIdentifier) else {
            return UITableViewCell()
        }
        cell.textLabel?.text = mediaItems[indexPath.row].bitRateString
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mediaItem = mediaItems[indexPath.row]
        videoPlayer.currentItem?.preferredPeakBitRate = mediaItem.bitrate
        tableView.isHidden = true
    }
}
