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

    weak var delegate: ChannelsProviderDelegate?
    let coreDataStack: CoreDataStack
    private var notificationToken: NSObjectProtocol?
    private var notificationMergeToken: NSObjectProtocol?
    /// Update fields by json values if the channel exists
    private let defaultMergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    /// A peristent history token used for fetching transactions from the store.
    private var lastToken: NSPersistentHistoryToken?

    // MARK: - Lifecycle

    init(with coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        /// Observe Core Data remote change notifications on the queue where the changes were made.
        notificationToken = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil, queue: nil,
            using: { _ in
            self.logger.debug("Received a persistent store remote change notification.")
            Task {
                do {
                    try await self.fetchPersistentHistoryTransactionsAndChanges()
                } catch {
                    self.delegate?.didGetError(error)
                }
            }
        })
        /// Notify delegate in order to update UI
        notificationMergeToken = NotificationCenter.default.addObserver(
            forName: NSManagedObjectContext.didMergeChangesObjectIDsNotification,
            object: coreDataStack.mainContext, queue: .main) { /*notification*/ _ in
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
        let taskContext = coreDataStack.newDerivedContext()
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

    /// Update view context with objectIDs from history change request.
    /// Tag: mergeChanges
    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        self.logger.debug("Received \(history.count) persistent history transactions.")
        let mainContext = coreDataStack.mainContext
        mainContext.perform {
            for transaction in history {
                mainContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
        }
    }

    /**
     Imports the channels feed into Core Data.
     Uses `NSBatchInsertRequest` (BIR) to import a JSON dictionary with  into the Core Data store on a private queue.
     */
    func saveChannels(from propertiesList: [ChannelProperties]) async throws {
        logger.debug("Start importing data to the store...")
        guard !propertiesList.isEmpty else { return }
        let taskContext = coreDataStack.newDerivedContext()
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
        /// Provide one dictionary at a time when the closure is called.
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
        let context = coreDataStack.mainContext
        let channels = try context.fetch(request)
        print("DEBUG: DB channels: \(channels.count)")
        return channels
    }
}
