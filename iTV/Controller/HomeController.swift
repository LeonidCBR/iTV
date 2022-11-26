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

    private var searchController: UISearchController!


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchData()
    }


    // MARK: - Methods

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private func configureUI() {
        tableView.register(ChannelCell.self, forCellReuseIdentifier: channelCell)
        configureSearchController()
    }

    private func configureSearchController() {
        searchController = UISearchController()


        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Напишите название телеканала"
//        searchController.searchResultsUpdater = self
//        searchController.hidesNavigationBarDuringPresentation = false
//        searchController.dimsBackgroundDuringPresentation = false

//        searchController.searchBar.sizeToFit()

        tableView.tableHeaderView = searchController.searchBar

//        navigationItem.searchController = searchController
//        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func fetchData() {
        fetchFromDB()


        
        fetchFromAPI()


    }

    private func fetchFromDB() {
        print("DEBUG: Loding from local DB")
        let request: NSFetchRequest<CDChannel> = CDChannel.fetchRequest()


        if let queryText = searchController.searchBar.text, !queryText.isEmpty {
            request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@", queryText)
        }

        do {
            channels = try context.fetch(request)
            print("DEBUG: DB channels: \(channels?.count ?? 0)")
            tableView.reloadData()
        } catch {
            let nserror = error as NSError
            showErrorMessage(nserror.localizedDescription)
        }
    }

    /**
     Find the channel from API in the DB
     Update data in the DB if the channel exists and fields are mismatched
     Add the channel to the DB if it does not exist
    */
    private func fetchFromAPI() {
        print("DEBUG: Fetch from API")
        let channelsUrl = URL(string: K.channelsUrlString)!
        ApiClient().downloadData(withUrl: channelsUrl) { [weak self] result in

            // MARK: --- BACKGROUND ---
            let backgroundQueue = DispatchQueue(label: "com.motodolphin.iTVbg")
            backgroundQueue.async {
/*
            guard let self = self else {
                return
            }
*/
                switch result {
                case .success(let jsonData):
                    do {
                        print("DEBUG: Parsing json data")
                        let feed = try JSONDecoder().decode(Feed.self, from: jsonData)
                        let apiChannels = feed.channels
                        try self?.syncData(with: apiChannels)

/*
                    DispatchQueue.main.async {

                        var shouldReloadTable = false
                        var channelIDsToReload = [Int64]()
                        print("DEBUG: Iterate api channels")
                        apiChannels.forEach { apiChannel in




                            // TODO: - Fix it!
                            // now we don't want to refer to self.channels?.first
                            // change it to bgChannels


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
*/
                    } catch {
                        DispatchQueue.main.async {
                            self?.showErrorMessage(error.localizedDescription)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.showErrorMessage(error.localizedDescription)
                    }
                } // switch



            } // backgroundQueue
        }

    }

    private func syncData(with apiChannels: [Channel]) throws {
        print("DEBUG: Sync data...")

        // MARK: --- BACKGROUND ---

        /*
         Create a new background context.
         Fetch data in the context.
         Look through the api channels, compare data, update it accordingly.
         Save the context.
         Notify the main thread to reload data from DB and update UI.
        */


        let bgContainer = NSPersistentContainer(name: "iTV")
        bgContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
                DispatchQueue.main.async {
                    self.showErrorMessage(error.localizedDescription)
                }
            }
        })
        let bgContext = bgContainer.newBackgroundContext()




        // fetch only count of records
        let bgRequest: NSFetchRequest<CDChannel> = CDChannel.fetchRequest()
        let countChannels = try bgContext.count(for: bgRequest)
        print("DEBUG: There \(countChannels) channels in the DB and \(apiChannels.count) API channels.")
        if countChannels != apiChannels.count {
            print("DEBUG: Clear all records in DB")
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDChannel")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try bgContext.execute(deleteRequest)
            print("DEBUG: Saving apiChannels to DB...")
            apiChannels.forEach { apiChannel in
                // Add new channel to DB
                let newChannel = CDChannel(context: bgContext)
                newChannel.id = Int64(apiChannel.id)
                newChannel.name = apiChannel.name
                newChannel.url = apiChannel.url
                newChannel.image = apiChannel.image
                newChannel.title = apiChannel.title
            }
            print("DEBUG: Save context")
            saveContext(bgContext)
            // notify main thread to reload data
            DispatchQueue.main.async {
                print("DEBUG: Notify main thread")
                self.fetchFromDB()
            }

        } else {

            print("DEBUG: Counts are match. Compare the data.")

            let bgChannels = try bgContext.fetch(bgRequest)
//        var channelIDsToReload = [Int64]()
            print("DEBUG: Iterate api channels")
//            var shouldReloadTable = false
            apiChannels.forEach { apiChannel in
                if let channel = bgChannels.first(where: { $0.id == apiChannel.id }) {
                    // Channel already exists
                    // Check the fields
                    if channel.name != apiChannel.name ||
                        channel.url != apiChannel.url ||
                        channel.image != apiChannel.image ||
                        channel.title != apiChannel.title {
                        channel.name = apiChannel.name
                        channel.url = apiChannel.url
                        channel.image = apiChannel.image
                        channel.title = apiChannel.title
//                        channelIDsToReload.append(channel.id)
//                        shouldReloadTable = true
                    }
                } else {
                    // Add new channel to DB
                    let newChannel = CDChannel(context: bgContext)
                    newChannel.id = Int64(apiChannel.id)
                    newChannel.name = apiChannel.name
                    newChannel.url = apiChannel.url
                    newChannel.image = apiChannel.image
                    newChannel.title = apiChannel.title
//                    shouldReloadTable = true
                }
            } // apiChannels.forEach

            if bgContext.hasChanges {
                print("DEBUG: There changes. Save background context.")
                saveContext(bgContext)
                // notify main thread to reload data
                DispatchQueue.main.async {
                    print("DEBUG: Notify main thread")
                    self.fetchFromDB()
                }
            } else {
                print("DEBUG: There is nothing to change.")
            }

        }

    }

/*
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
*/
    private func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                DispatchQueue.main.async {
                    let nserror = error as NSError
                    self.showErrorMessage("\(nserror), \(nserror.userInfo)")
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

//    private func search(for queryString: String) {
//        print("DEBUG: Search for = \"\(queryString)\"")
//
//
//
//    }


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
        guard let channel = channels?[indexPath.row], let mediaUrlString = channel.url, let _ = URL(string: mediaUrlString) else {
            showErrorMessage("Неверная ссылка!")
            return
        }
        let videoViewController = VideoViewController(with: channel)
        if let imagePath = channel.image {
            imageManager.downloadImage(with: imagePath) { result, path in
                if case .success(let image) = result {
                    videoViewController.setLogoImage(to: image)
                }
            }
        }
        videoViewController.modalPresentationStyle = .fullScreen
        present(videoViewController, animated: true, completion: nil)
    }

}


// MARK: - ChannelCellDelegate

extension HomeController: ChannelCellDelegate {
    func favoriteChanged(cell: UITableViewCell, channel: CDChannel, isFavorite: Bool) {
        if let row = tableView.indexPath(for: cell)?.row {
            channels?[row].isFavorite = isFavorite
            saveContext(context)
        }
    }
}

extension HomeController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

// ???
        dismiss(animated: true, completion: nil)


//        if let queryText = searchBar.text, !queryText.isEmpty {
//            search(for: queryText)
//        }
        fetchFromDB()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.resignFirstResponder()
        searchController.searchBar.text = ""
        fetchFromDB()
    }
}
