//
//  TableViewController.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import UIKit
import AVFoundation
import CoreData


class HomeController: UIViewController {

    // MARK: - Properties

    private let imageManager: ImageProvider
    private let channelCell = "channelCellIdentifier"
    private var channels: [Channel] = []
    private var searchBar: UISearchBar!
    private var favoriteFilter: FavoriteFilterView!
    private var tableView: UITableView!


    // MARK: - Lifecycle

    init(with imageManager: ImageProvider) {
        self.imageManager = imageManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ChannelsProvider.shared.delegate = self
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
        let idx = favoriteFilter.selectedSegmentIndex
        let favoriteFilterOption = FavoriteFilterOption(rawValue: idx)!
        do {
            channels = try ChannelsProvider.shared.fetchChannels(searchText: searchBar.text, filter: favoriteFilterOption)
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
    private func importChannelsFromAPI() {
        Task {
            do {
                try await ChannelsProvider.shared.importChannels()
            } catch {
                showErrorMessage(error.localizedDescription)
            }
        }
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

        // Check if all channels are selected
        guard case .all = FavoriteFilterOption(rawValue: favoriteFilter.selectedSegmentIndex) else {
            /**
             There is the favorite tab has been selected
             Delete the channel from favorites and update UI
            */
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
        let channelProperties = ChannelProperties(from: channel)
        let videoViewController = VideoViewController(with: channelProperties)
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


// MARK: - ChannelsProviderDelegate

extension HomeController: ChannelsProviderDelegate {
    func dataDidUpdate() {
        loadPersistentChannels()
    }

    func didGetError(_ error: Error) {
        showErrorMessage("\(error.localizedDescription)")
    }
}
