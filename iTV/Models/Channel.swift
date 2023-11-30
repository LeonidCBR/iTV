//
//  Channel.swift
//  iTV
//
//  Created by Яна Латышева on 14.12.2022.
//

import Foundation
import CoreData

/// TV channel
final class Channel: NSManagedObject {
    /// A unique identifier used to avoid duplicates in the persistent store.
    /// Constrain the Channel entity on this attribute in the data model editor.
    @NSManaged var id: Int
    /// A name of the channel
    @NSManaged var name: String
    /// URL string to the media content playing on the channel
    @NSManaged var url: String
    /// URL string to logo image of the channel
    @NSManaged var image: String
    /// A title of the current show playing on the channel
    @NSManaged var title: String
    @NSManaged var isFavorite: Bool

    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(false, forKey: #keyPath(Channel.isFavorite))
    }
}
