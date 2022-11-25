//
//  TableViewController.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import UIKit
import AVFoundation

import AVKit
import CoreData

class HomeController: UITableViewController {

    // MARK: - Properties
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let imageManager = ImageManager()
    private let channelCell = "channelCellIdentifier"
    private var channels: [CDChannel]?


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
        fetchFromDB()
        fetchFromAPI()
    }

    private func fetchFromDB() {
        print("DEBUG: Loding from local DB")
        let request: NSFetchRequest<CDChannel> = CDChannel.fetchRequest()
        do {
            channels = try context.fetch(request)
            print("DEBUG: DB channels: \(channels?.count ?? 0)")
            tableView.reloadData()
        } catch {
            let nserror = error as NSError
            showErrorMessage(nserror.localizedDescription)
        }
    }

    private func fetchFromAPI() {
        print("DEBUG: Fetch from API")
        let channelsUrl = URL(string: K.channelsUrlString)!
        ApiClient().downloadData(withUrl: channelsUrl) { [weak self] result in

            // --- BACKGROUND ---

            // TODO: create here a new context
            // TODO: use predicate

            guard let self = self else { // !!! delete it
                return
            }

            switch result {
            case .success(let jsonData):
                do {
                    print("DEBUG: Parsing json data")
                    let feed = try JSONDecoder().decode(Feed.self, from: jsonData)
                    let apiChannels = feed.channels

                    // TODO: Consider to delete it
                    DispatchQueue.main.async {

                        var shouldReloadTable = false
                        var channelIDsToReload = [Int64]()
                        print("DEBUG: Iterate api channels")
                        apiChannels.forEach { apiChannel in

                            // TODO: consider to use predicate!!!

                            /**
                             Find the channel from API in the DB
                             Update data in the DB if the channel exists and fields are mismatched
                             Add the channel to the DB if it does not exist
                            */
                            if let channel = self.channels?.first(where: { $0.id == apiChannel.id }) {
                                if channel.name != apiChannel.name ||
                                    channel.url != apiChannel.url ||
                                    channel.image != apiChannel.image ||
                                    channel.title != apiChannel.title {
                                    channel.name = apiChannel.name
                                    channel.url = apiChannel.url
                                    channel.image = apiChannel.image
                                    channel.title = apiChannel.title
                                    channelIDsToReload.append(channel.id)
                                }
                            } else {
                                // Add new channel to DB
                                let newChannel = CDChannel(context: self.context)
                                newChannel.id = Int64(apiChannel.id)
                                newChannel.name = apiChannel.name
                                newChannel.url = apiChannel.url
                                newChannel.image = apiChannel.image
                                newChannel.title = apiChannel.title
                                shouldReloadTable = true
                            }

                        } //apiChannels.forEach

                        // TODO: Remember about main or background thread
                        self.saveContext()

                        if shouldReloadTable {
                            print("DEBUG: Should reload table")
                            // TODO: Remember about main thread
                            self.fetchFromDB()
                        } else {
                            print("DEBUG: There is no new channels")
                            if channelIDsToReload.count > 0 {
                                print("DEBUG: Reload updated channels \(channelIDsToReload.count)...")
                                // TODO: Remember about main or background thread
                                self.reloadCells(with: channelIDsToReload)
                            }
                        }

                    } //DispatchQueue.main.async

                } catch {
                    DispatchQueue.main.async {
                        self.showErrorMessage(error.localizedDescription)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showErrorMessage(error.localizedDescription)
                }
            }
        }

    }

    private func reloadCells(with ids: [Int64]) {
        let paths = ids.compactMap { channelId -> IndexPath? in
            if let rowId = channels?.firstIndex(where: { $0.id == channelId }) {
                return IndexPath(row: rowId, section: 0)
            } else {
                return nil
            }
        }
        tableView.reloadRows(at: paths, with: .none)
    }

    private func saveContext() { //saveContext(_ context: NSManagedObjectContext)
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                showErrorMessage("\(nserror), \(nserror.userInfo)")
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
        return channels?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: channelCell, for: indexPath) as! ChannelCell
        cell.delegate = self
        cell.clearLogoImage()
        cell.channel = channels?[indexPath.row]
        guard let imagePath = channels?[indexPath.row].image else {
            print("DEBUG: ID[\(channels?[indexPath.row].id ?? 0)] image is nil.")
            return cell
        }
        imageManager.downloadImage(with: imagePath) { result, path in
            guard path == imagePath else {
                print("DEBUG: Image path mismatch")
                return
            }
            if case .success(let image) = result {
                // TODO: Consider to use [weak cell]
                cell.setLogoImage(to: image)
//                cell?.setLogoImage(to: image)
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let mediaUrlString = channels?[indexPath.row].url, let url = URL(string: mediaUrlString) else {
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
    func favoriteChanged(cell: UITableViewCell, channel: CDChannel, isFavorite: Bool) {
        if let row = tableView.indexPath(for: cell)?.row {
            channels?[row].isFavorite = isFavorite
            saveContext()
        }
    }
}
