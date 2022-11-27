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


    // TODO: Consider to use UISegmentedControll
//    private var favoriteFilterView: FavoriteFilterView!
    private var segmentedControl: UISegmentedControl!


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchFromDB()


        // TODO: Uncomment !!!

//        fetchFromAPI()
    }
/*
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.tableHeaderView!.frame.size = CGSize(width: tableView.frame.width, height: CGFloat(100.0))
    }
*/

    // MARK: - Methods

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private func configureUI() {
        tableView.register(ChannelCell.self, forCellReuseIdentifier: channelCell)
        configureSearchController()
//        configureFavoriteFilterView()
//        configureHeaderView()
    }

    private func configureSearchController() {
        searchController = UISearchController()
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Напишите название телеканала"
//        searchController.searchResultsUpdater = self
//        searchController.dimsBackgroundDuringPresentation = false
//        searchController.searchBar.sizeToFit()
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false

//        tableView.tableHeaderView = searchController.searchBar
        navigationItem.searchController = searchController

        //self.navigationItem.titleView = segmentedControl

//        let favoriteFilterOptions = FavoriteFilterOption.allCases
        let favoriteFilterOptions: [FavoriteFilterOption] = [.all, .favorites]
        let options = favoriteFilterOptions.map { $0.description }
//        let options = ["Все", "Избранные"]

        segmentedControl = UISegmentedControl(items: options)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(filterValueChanged), for: .valueChanged)
        navigationItem.titleView = segmentedControl
    }
/*
    private func configureHeaderView() {
        // Configure search bar
        searchController = UISearchController()
        let searchBar = searchController.searchBar
        searchBar.delegate = self
        searchBar.placeholder = "Напишите название телеканала"
        // Configure header view
        let headerView = UIView()
        headerView.addSubview(searchBar)
        searchBar.anchor(top: headerView.topAnchor,
                         bottom: headerView.bottomAnchor, // !!!
                         leading: headerView.leadingAnchor,
                         trailing: headerView.trailingAnchor)

        favoriteFilterView = FavoriteFilterView()
//        headerView.addSubview(favoriteFilterView)
//        favoriteFilterView.anchor(top: searchBar.bottomAnchor,
//                                  bottom: headerView.bottomAnchor,
//                                  leading: headerView.leadingAnchor,
//                                  trailing: headerView.trailingAnchor)

//        headerView.frame.size = CGSize(width: tableView.frame.width, height: CGFloat(100.0))
        tableView.tableHeaderView = headerView
    }
*/

    /**
     Load channels from DB.
     Reload the table view.
     */
    private func fetchFromDB() {
        print("DEBUG: Loding from local DB")
        let request: NSFetchRequest<CDChannel> = CDChannel.fetchRequest()

        // TODO: use filter
//        let option = FavoriteFilterOption(rawValue: segmentedControl.selectedSegmentIndex)
//        let idOption = segmentedControl.selectedSegmentIndex
        let favoriteFilterOption = FavoriteFilterOption(rawValue: segmentedControl.selectedSegmentIndex)!
        print("DEBUG: Filter index=\(favoriteFilterOption.description)")

        if let queryText = searchController.searchBar.text, !queryText.isEmpty {
            if case .favorites = favoriteFilterOption {  //idOption == 1 {
                request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@ AND isFavorite == YES", queryText)
            } else {
                request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@", queryText)
            }
        } else {
            if case .favorites = favoriteFilterOption { // idOption == 1 {
                request.predicate = NSPredicate(format: "isFavorite == YES")
            }
        }


/*
        if let queryText = searchController.searchBar.text, !queryText.isEmpty {
            request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@" + favoritesQuery, queryText)
        }
*/
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
     Fetch channels from API.
     Find the channels from API in the DB.
     Update data in the DB if the channel exists and fields are mismatched.
     Add the channel to the DB if it does not exist.
    */
    private func fetchFromAPI() {
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
    }

    /**
     Create a new background context.
     Fetch data in the context.
     Look through the api channels, compare data, update it accordingly.
     Save the context.
     Notify the main thread to reload data from DB and update UI.
    */
    private func syncData(with apiChannels: [Channel]) throws {

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
                self.fetchFromDB()
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
                    self.fetchFromDB()
                }
            } else {
                print("DEBUG: There is nothing to change.")
            }
        } // if countChannels != apiChannels.count
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


    // MARK: - Selectors
    @objc private func filterValueChanged() {
        print("DEBUG: \(#function)")
        //print("DEBUG: Filter index=\(segmentedControl.selectedSegmentIndex)")
        fetchFromDB()
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
                cell.setLogoImage(to: image)
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


// MARK: - UISearchBarDelegate

extension HomeController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        fetchFromDB()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.text = ""
        fetchFromDB()
    }
}
