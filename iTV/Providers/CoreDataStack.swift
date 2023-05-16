//
//  CoreDataStack.swift
//  iTV
//
//  Created by Яна Латышева on 15.05.2023.
//

import Foundation
import CoreData

class CoreDataStack {
    let mainContext: NSManagedObjectContext
    let storeContainer: NSPersistentContainer
    /// Update fields by json values if the channel exists
    let defaultMergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

    init(isEphemeral: Bool = false) throws {
        storeContainer = NSPersistentContainer(name: "iTV")
        if isEphemeral {
            let persistentStoreDescription = NSPersistentStoreDescription()
            persistentStoreDescription.type = NSInMemoryStoreType
            storeContainer.persistentStoreDescriptions = [persistentStoreDescription]
        }
        guard let description = storeContainer.persistentStoreDescriptions.first else {
            throw ChannelError.persistentStoreDescriptionError
        }
        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber,
                              forKey: NSPersistentHistoryTrackingKey)
        storeContainer.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                // TODO: Handle the error
                fatalError("Unresolved error \(error), \(error.userInfo)")
//                throw ChannelError.unexpectedError(error: error)
            }
        }
        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        storeContainer.viewContext.automaticallyMergesChangesFromParent = false
        storeContainer.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        storeContainer.viewContext.mergePolicy = defaultMergePolicy
        storeContainer.viewContext.undoManager = nil
        storeContainer.viewContext.shouldDeleteInaccessibleFaults = true
        mainContext = storeContainer.viewContext
    }

    public func newDerivedContext() -> NSManagedObjectContext {
        let context = storeContainer.newBackgroundContext()
        context.mergePolicy = defaultMergePolicy
        return context
    }

    public func saveContext() async throws {
        try await saveContext(mainContext)
    }

    public func saveContext(_ context: NSManagedObjectContext) async throws {
        if context != mainContext {
            try await saveDerivedContext(context)
            return
        }
        do {
            try await context.perform {
                try context.save()
            }
        } catch {
            throw ChannelError.unexpectedError(error: error)
        }
    }

    public func saveDerivedContext(_ context: NSManagedObjectContext) async throws {
        do {
            try await context.perform {
                try context.save()
            }
            try await saveContext(mainContext)
        } catch {
            throw ChannelError.unexpectedError(error: error)
        }
    }
}
