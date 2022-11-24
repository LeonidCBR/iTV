//
//  TableViewController.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import UIKit
import AVFoundation

import AVKit

class HomeController: UITableViewController {

    // MARK: - Properties

    private let channelCell = "channelCellIdentifier"
    private var channels: [Channel] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private let imageManager = ImageManager()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchData()
    }


    // MARK: - Methods

    private func configureUI() {
        tableView.register(ChannelCell.self, forCellReuseIdentifier: channelCell)
    }

    private func fetchData() {

        // TODO: fetch data from Core Data


        // TODO: fetch data from API and update UI


        let channelsUrl = URL(string: K.channelsUrlString)!
        ApiClient().downloadData(withUrl: channelsUrl) { [weak self] result in
            switch result {
            case .success(let jsonData):
                do {
                    let feed = try JSONDecoder().decode(Feed.self, from: jsonData)
                    DispatchQueue.main.async {
                        self?.channels = feed.channels
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.showErrorMessage(error.localizedDescription)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showErrorMessage(error.localizedDescription)
                }
            }
        }
    }

    private func showErrorMessage(_ message: String) {
        print(message)
        let alertController = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: channelCell, for: indexPath) as! ChannelCell
        cell.delegate = self
        cell.clearLogoImage()
        let channel = channels[indexPath.row]
        cell.setChannel(to: channel)

        guard let imagePath = channel.image else {
            print("DEBUG: ID[\(channel.id)] image is nil.")
            return cell
        }

        imageManager.downloadImage(with: imagePath) { result, path in
            guard path == channel.image else {
                print("DEBUG: Image path mismatch")
                return
            }
            if case .success(let image) = result {
                cell.setLogoImage(to: image)
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let mediaUrlString = channels[indexPath.row].url
        guard let url = URL(string: mediaUrlString) else {
            showErrorMessage("Неверная ссылка!")
            return
        }

        // TODO: Create a custom player controller

        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        present(controller, animated: true) {
            player.play()
        }
    }

}


// MARK: - ChannelCellDelegate

extension HomeController: ChannelCellDelegate {
    func favoriteChanged(cell: UITableViewCell, channelId: Int, isFavorite: Bool) {
        if let row = tableView.indexPath(for: cell)?.row {
            channels[row].isFavorite = isFavorite

            // TODO: save favorite status to DB
            
            print("DEBUG: Save favorite status")
        }
    }
}
