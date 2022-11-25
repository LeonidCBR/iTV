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

//    private var channels: [Channel] = [] {
//    private var channels: [CDChannel]? {
//        didSet {
//            tableView.reloadData()
//        }
//    }
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


        // TODO: fetch data from API and update UI

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

        /*
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
        */


        // TODO: Consider to do it in the background queue


        // fetch json data from api
        let channelsUrl = URL(string: K.channelsUrlString)!
        ApiClient().downloadData(withUrl: channelsUrl) { [weak self] result in

            // TODO: maybe use predicate ???
            // then delete it
            guard let self = self else {
                return
            }

            switch result {
            case .success(let jsonData):
                do {
                    // parse json to feed.channels = apiChannels
                    print("DEBUG: Parsing json data")
                    let feed = try JSONDecoder().decode(Feed.self, from: jsonData)
                    let apiChannels = feed.channels


                    // TODO: Consider to delete it
                    DispatchQueue.main.async {

                        var shouldReloadTable = false
                        print("DEBUG: Iterate api channels")
                        apiChannels.forEach { apiChannel in




                            // TODO: consider to use predicate!!!




                            if let channel = self.channels?.first(where: { $0.id == apiChannel.id }) {
                                // TODO: Add an extension
//                                channel.update(with: apiChannel)

                                // if the fields mismatch - update it then find the row and reload it
                                if channel.name != apiChannel.name ||
                                    channel.url != apiChannel.url ||
                                    channel.image != apiChannel.image ||
                                    channel.title != apiChannel.title {

                                    channel.name = apiChannel.name
                                    channel.url = apiChannel.url
                                    channel.image = apiChannel.image
                                    channel.title = apiChannel.title

                                    if let dbChannelIndex = self.channels?.firstIndex(of: channel) {
                                        let indexPath = IndexPath(row: dbChannelIndex, section: 0)
                                        print("DEBUG: Reload row at index - \(indexPath.row)")
                                        // TODO: Remember about main thread
                                        self.tableView.reloadRows(at: [indexPath], with: .none)
                                    }
                                }
                            } else {

                                // TODO: Add an extension
//                                let newChannel = CDChannel(from: apiChannel)
                                let newChannel = CDChannel(context: self.context)
                                newChannel.id = Int64(apiChannel.id)
                                newChannel.name = apiChannel.name
                                newChannel.url = apiChannel.url
                                newChannel.image = apiChannel.image
                                newChannel.title = apiChannel.title
                                shouldReloadTable = true
                            }

//                            if channels?.count == 0 {
//                                let newChannel = CDChannel(currentApiChannel)
//                            } else {
//                                // ищем текущий канал в БД
//                                if fetched dbChannel where id == currentApiChannel.id {
//                                    dbChannel.update(currentApiChannel)
//                                } else {
//                                    let newChannel = CDChannel(currentApiChannel)
//                                }
//                            }
                        }
                        if shouldReloadTable {
                            print("DEBUG: Should reload table")
                            self.fetchFromDB()
                        } else {
                            print("DEBUG: There is nothing to reload")
                        }

                        self.saveContext()
                    }

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
        /**

         apiChannels.forEach { currentApiChannel
            if channels.count == 0 {
                let newChannel = CDChannel(currentApiChannel)
            } else {
                // ищем текущий канал в БД
                if fetched dbChannel where id == currentApiChannel.id {
                    dbChannel.update(currentApiChannel)
                } else {
                    let newChannel = CDChannel(currentApiChannel)
                }
            }
         }

         DispatchQueue.main.async:
         saveContext()
         tableView.reloadData

         */
    }

    private func saveContext() {
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
//        return channels.count
        return channels?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: channelCell, for: indexPath) as! ChannelCell
        cell.delegate = self
        cell.clearLogoImage()



//        let channel = channels[indexPath.row]
//        guard let cdChannel = channels?[indexPath.row] else {
//            return cell
//        }
        cell.channel = channels?[indexPath.row]



//        cell.setChannel(to: channel)


        

        //guard let imagePath = channel.image else {
        guard let imagePath = channels?[indexPath.row].image else {
            //print("DEBUG: ID[\(channel.id)] image is nil.")
            print("DEBUG: ID[\(channels?[indexPath.row].id ?? 0)] image is nil.")
            return cell
        }



        // TODO: Consider to use [weak cell]


        imageManager.downloadImage(with: imagePath) { result, path in
            //guard path == channel.image else {
            guard path == imagePath else {
                print("DEBUG: Image path mismatch")
                return
            }
            if case .success(let image) = result {
                cell.setLogoImage(to: image)
//                cell?.setLogoImage(to: image)
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)



//        let mediaUrlString = channels[indexPath.row].url
//        guard let url = URL(string: mediaUrlString) else {
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
/*
    func favoriteChanged(cell: UITableViewCell, channelId: Int, isFavorite: Bool) {
        if let row = tableView.indexPath(for: cell)?.row {
            channels[row].isFavorite = isFavorite

            // TODO: save favorite status to DB
            
            print("DEBUG: Save favorite status")
        }
    }
*/
}
