//
//  TableViewController.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import UIKit
import AVFoundation
import CoreData


class HomeController: UIViewController { // UITableViewController {

    // MARK: - Properties

    private let imageManager = ImageManager()
    private let channelCell = "channelCellIdentifier"
    private var channels: [Channel] = []
    private var searchBar: UISearchBar!
    private var favoriteFilter: FavoriteFilterView!
    private var tableView: UITableView!


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        loadPersistentChannels()
        importChannelsFromAPI()
    }


    // MARK: - Methods

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private func configureUI() {
        view.backgroundColor = K.bgColor
        configureSearchBar()
        configureFavoriteFilter()
        configureTableView()
    }

    private func configureSearchBar() {
        searchBar = UISearchBar()
        searchBar.backgroundColor = K.bgColor
        searchBar.barTintColor = K.bgColor
        searchBar.tintColor = .white
        searchBar.searchTextField.textColor = .white
        searchBar.delegate = self
        searchBar.placeholder = "Напишите название телеканала"
        view.addSubview(searchBar)
        searchBar.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                         leading: view.safeAreaLayoutGuide.leadingAnchor,
                         trailing: view.safeAreaLayoutGuide.trailingAnchor)
    }

    private func configureFavoriteFilter() {
        favoriteFilter = FavoriteFilterView()
        favoriteFilter.delegate = self
        view.addSubview(favoriteFilter)
        favoriteFilter.anchor(top: searchBar.bottomAnchor,
                              leading: view.safeAreaLayoutGuide.leadingAnchor,
                              trailing: view.safeAreaLayoutGuide.trailingAnchor,
                              height: 50.0)
    }

    private func configureTableView() {
        tableView = UITableView()
        tableView.backgroundColor = K.dark
        tableView.register(ChannelCell.self, forCellReuseIdentifier: channelCell)
        view.addSubview(tableView)
        tableView.anchor(top: favoriteFilter.bottomAnchor,
                         bottom: view.safeAreaLayoutGuide.bottomAnchor,
                         leading: view.safeAreaLayoutGuide.leadingAnchor,
                         trailing: view.safeAreaLayoutGuide.trailingAnchor)
        tableView.delegate = self
        tableView.dataSource = self
    }

    /**
     Load channels from DB.
     Reload the table view.
     */
    private func loadPersistentChannels() {
        let favoriteFilterOption = FavoriteFilterOption(rawValue: favoriteFilter.selectedSegmentIndex)!
        do {
            channels = try ChannelsProvider.shared.fetchChannels(searchText: searchBar.text, filter: favoriteFilterOption)
        tableView.reloadData()
        } catch {
            let nserror = error as NSError
            showErrorMessage(nserror.localizedDescription)
        }
/*
        print("DEBUG: Loding from local DB")
        let request: NSFetchRequest<Channel> = CDChannel.fetchRequest()

        let favoriteFilterOption = FavoriteFilterOption(rawValue: favoriteFilter.selectedSegmentIndex)!
        print("DEBUG: Filter index=\(favoriteFilterOption.description)")

        if let queryText = searchBar.text, !queryText.isEmpty {
            if case .favorites = favoriteFilterOption {
                // search by name & favorite
                request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@ AND isFavorite == YES", queryText)
            } else {
                // search by name
                request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@", queryText)
            }
        } else {
            if case .favorites = favoriteFilterOption {
                // only favorite
                request.predicate = NSPredicate(format: "isFavorite == YES")
            }
        }

        do {
            channels = try context.fetch(request)
            print("DEBUG: DB channels: \(channels?.count ?? 0)")
            tableView.reloadData()
        } catch {
            let nserror = error as NSError
            showErrorMessage(nserror.localizedDescription)
        }
*/
    }

    /**
     Fetch channels from API.
     Find the channels from API in the DB.
     Update data in the DB if the channel exists and fields are mismatched.
     Add the channel to the DB if it does not exist.
    */
//    @MainActor
    private func importChannelsFromAPI() {
        Task {
            do {
                try await ChannelsProvider.shared.importChannels()
            } catch {
                showErrorMessage(error.localizedDescription)
            }
        }
/*
        print("DEBUG: Fetch from API")
        let channelsUrl = URL(string: K.channelsUrlString)!
        ApiClient().downloadData(withUrl: channelsUrl) { [weak self] result in
            let backgroundQueue = DispatchQueue(label: "com.motodolphin.iTVbg")
            backgroundQueue.async {
                switch result {
                case .success(let jsonData):
                    do {
                        print("DEBUG: Parsing json data")
                        let feed = try JSONDecoder().decode(Feed.self, from: jsonData)
                        let apiChannels = feed.channels
                        try self?.syncData(with: apiChannels)

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
        } // ApiClient().downloadData

*/
    }

    /**
     Create a new background context.
     Fetch data in the context.
     Look through the api channels, compare data, update it accordingly.
     Save the context.
     Notify the main thread to reload data from DB and update UI.
    */
/*
    private func syncData(with apiChannels: [ChannelProperties]) throws {

        // TODO: Do a refactoring

        print("DEBUG: Sync data...")
        let bgContainer = NSPersistentContainer(name: "iTV")
        bgContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    self.showErrorMessage(error.localizedDescription)
                }
            }
        })
        let bgContext = bgContainer.newBackgroundContext()

        // Fetch only count of records
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
            // Notify main thread to reload data and update UI
            DispatchQueue.main.async {
                print("DEBUG: Notify main thread")
                self.loadPersistentChannels()
            }

        } else {
            print("DEBUG: Counts are match. Compare the data by iterating API channels.")
            let bgChannels = try bgContext.fetch(bgRequest)
            apiChannels.forEach { apiChannel in
                if let channel = bgChannels.first(where: { $0.id == apiChannel.id }) {
                    // Channel already exists. Check the fields.
                    if channel.name != apiChannel.name ||
                        channel.url != apiChannel.url ||
                        channel.image != apiChannel.image ||
                        channel.title != apiChannel.title {
                        channel.name = apiChannel.name
                        channel.url = apiChannel.url
                        channel.image = apiChannel.image
                        channel.title = apiChannel.title
                    }
                } else {
                    // Add new channel to DB
                    let newChannel = CDChannel(context: bgContext)
                    newChannel.id = Int64(apiChannel.id)
                    newChannel.name = apiChannel.name
                    newChannel.url = apiChannel.url
                    newChannel.image = apiChannel.image
                    newChannel.title = apiChannel.title
                }
            } // apiChannels.forEach

            if bgContext.hasChanges {
                print("DEBUG: There are changes. Save background context.")
                saveContext(bgContext)
                // notify main thread to reload data
                DispatchQueue.main.async {
                    print("DEBUG: Notify main thread")
                    self.loadPersistentChannels()
                }
            } else {
                print("DEBUG: There is nothing to change.")
            }
        } // if countChannels != apiChannels.count
    }
*/

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

/*
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
*/
    private func showErrorMessage(_ message: String) {
        print(message)
        let alertController = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }

}


// MARK: - Table view data source

extension HomeController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: channelCell, for: indexPath) as! ChannelCell
        cell.delegate = self
        cell.clearLogoImage()
        cell.channel = channels[indexPath.row]

        let imagePath = channels[indexPath.row].image
        guard !imagePath.isEmpty else {
            print("DEBUG: ID[\(channels[indexPath.row].id)] image is nil or empty.")
            return cell
        }
        imageManager.downloadImage(with: imagePath) { result, path in
            guard path == imagePath else {
                print("DEBUG: Image path mismatch")
                return
            }
            if case .success(let image) = result {
                cell.setLogoImage(to: image)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard case .all = FavoriteFilterOption(rawValue: favoriteFilter.selectedSegmentIndex) else {
            // Удаляем из избранных канал
            print("DEBUG: Delete channel from favorites")
            let channel = channels[indexPath.row]
            channel.isFavorite = false


            // TODO: Consider to remove the channel from the list and remove the row

//            saveContext(context)
            ChannelsProvider.shared.saveContext()


            loadPersistentChannels()
            return
        }

        // Открываем плеер, так как выбраны "Все" каналы
        let channel = channels[indexPath.row]
        guard let _ = URL(string: channel.url) else {
            showErrorMessage("Неверная ссылка!")
            return
        }
        let videoViewController = VideoViewController(with: channel)
        if !channel.image.isEmpty {
            imageManager.downloadImage(with: channel.image) { result, path in
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
    func favoriteChanged(cell: UITableViewCell, channel: Channel, isFavorite: Bool) {
        if let row = tableView.indexPath(for: cell)?.row {
            channels[row].isFavorite = isFavorite

//            saveContext(context)
            ChannelsProvider.shared.saveContext()
        }
    }
}


// MARK: - UISearchBarDelegate

extension HomeController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        loadPersistentChannels()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        searchBar.text = ""
        loadPersistentChannels()
    }
}


// MARK: - FavoriteFilterViewDelegate

extension HomeController: FavoriteFilterViewDelegate {
    func filterValueChanged() {
        print("DEBUG: Call delegate of the filter view")
        loadPersistentChannels()
    }
}
