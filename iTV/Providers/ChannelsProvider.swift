//
//  ChannelsProvider.swift
//  iTV
//
//  Created by Яна Латышева on 06.12.2022.
//

import Foundation
import CoreData
import OSLog

protocol ChannelsProviderDelegate: AnyObject {
    func dataDidUpdate()
    func didGetError(_ error: Error)
}

final class ChannelsProvider {

    // MARK: - Properties

    let logger = Logger(subsystem: "com.motodolphin.iTV", category: "persistence")

    let url = URL(string: "http://limehd.online/playlist/channels.json")!

    // update fields by json values if the channel exists
    private let defaultMergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

    weak var delegate: ChannelsProviderDelegate?
    
    private var notificationToken: NSObjectProtocol?
    private var notificationMergeToken: NSObjectProtocol?

    /// A peristent history token used for fetching transactions from the store.
    private var lastToken: NSPersistentHistoryToken?

    static let shared = ChannelsProvider()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "iTV")
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber,
                              forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = defaultMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }()


    // MARK: - Lifecycle

    private init() {
        // Observe Core Data remote change notifications on the queue where the changes were made.
        notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil, using: { _ in
            self.logger.debug("Received a persistent store remote change notification.")
            Task {
                do {
                    try await self.fetchPersistentHistoryTransactionsAndChanges()
                } catch {
                    self.delegate?.didGetError(error)
                }
            }
        })

        // Notify delegate in order to update UI
        notificationMergeToken = NotificationCenter.default.addObserver(forName: NSManagedObjectContext.didMergeChangesObjectIDsNotification, object: persistentContainer.viewContext, queue: .main) { /*notification*/ _ in
            self.logger.debug("Received a merge notification.")
            self.delegate?.dataDidUpdate()
        }
        
    }

    deinit {
        if let observer = notificationToken {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = notificationMergeToken {
            NotificationCenter.default.removeObserver(observer)
        }
    }


    // MARK: - Methods
    
    private func fetchPersistentHistoryTransactionsAndChanges() async throws {
        let taskContext = newTaskContext()
        taskContext.name = "persistentHistoryContext"
        logger.debug("Start fetching persistent history changes from the store...")

        try await taskContext.perform {
            // Execute the persistent history change since the last transaction.
            /// - Tag: fetchHistory
            let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
            let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
            if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
               !history.isEmpty {
                self.mergePersistentHistoryChanges(from: history)
                return
            }

            self.logger.debug("No persistent history transactions found.")
            throw ChannelError.persistentHistoryChangeError
        }

        logger.debug("Finished merging history changes.")
    }

    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        self.logger.debug("Received \(history.count) persistent history transactions.")
        // Update view context with objectIDs from history change request.
        /// - Tag: mergeChanges
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            for transaction in history {
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
        }
    }

    /// Creates and configures a private queue context.
    private func newTaskContext() -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = defaultMergePolicy
        return taskContext
    }

    /// Fetches the channels feed from the remote server, and imports it into Core Data.
    func importChannels() async throws {


        // TODO: Inject instance of NetworkProvider

        
        let channelsData = try await NetworkProvider().downloadData(withUrl: url)

        do {
            let channelPropertiesList = try parseChannelPropertiesList(from: channelsData)
            logger.debug("Received \(channelPropertiesList.count) records.")

            // Import the GeoJSON into Core Data.
            try await saveChannels(from: channelPropertiesList)
            logger.debug("Finished importing data.")
        } catch {
            throw ChannelError.wrongDataFormat(error: error)
        }
    }

    func parseChannelPropertiesList(from data: Data) throws -> [ChannelProperties] {
        // Decode the GeoJSON into a data model.
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        let geoJSON = try jsonDecoder.decode(GeoJSON.self, from: data)
        return geoJSON.channelPropertiesList
    }

    /// Uses `NSBatchInsertRequest` (BIR) to import a JSON dictionary into the Core Data store on a private queue.
    private func saveChannels(from propertiesList: [ChannelProperties]) async throws {
        logger.debug("Start importing data to the store...")
        guard !propertiesList.isEmpty else { return }

        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importChannels"

        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = self.newBatchInsertRequest(with: propertiesList)
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }
            self.logger.debug("Failed to execute batch insert request.")
            throw ChannelError.batchInsertError
        }

        logger.debug("Successfully inserted data.")
    }

    private func newBatchInsertRequest(with propertyList: [ChannelProperties]) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count

        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: Channel.entity(), dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: propertyList[index].dictionaryValue)
            index += 1
            return false
        })
        return batchInsertRequest
    }

    func fetchChannels(searchText: String?, filter: FavoriteFilterOption) throws -> [Channel] {
        logger.debug("Fetching channels from DB...")
        let request = NSFetchRequest<Channel>(entityName: String(describing: Channel.self))

        print("DEBUG: Filter index=\(filter.description)")

        if let queryText = searchText, !queryText.isEmpty {
            if case .favorites = filter {
                // search by name & favorite
                request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@ AND isFavorite == YES", queryText)
            } else {
                // search by name
                request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@", queryText)
            }
        } else {
            if case .favorites = filter {
                // only favorite
                request.predicate = NSPredicate(format: "isFavorite == YES")
            }
        }

        let context = persistentContainer.viewContext
        let channels = try context.fetch(request)
        print("DEBUG: DB channels: \(channels.count)")
        return channels
    }

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}


