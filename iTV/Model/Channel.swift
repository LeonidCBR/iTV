//
//  Channel.swift
//  iTV
//
//  Created by Яна Латышева on 14.12.2022.
//

import Foundation
import CoreData

class Channel: NSManagedObject {
    // A unique identifier used to avoid duplicates in the persistent store.
    // Constrain the Channel entity on this attribute in the data model editor.
    @NSManaged var id: Int

    @NSManaged var name: String
    @NSManaged var url: String
    @NSManaged var image: String
    @NSManaged var title: String
    @NSManaged var isFavorite: Bool
}
