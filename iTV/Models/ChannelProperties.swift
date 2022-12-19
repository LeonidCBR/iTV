//
//  Channel.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import Foundation

struct ChannelProperties: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id
        case name = "name_ru"
        case url
        // TODO: Consider to rename to "imagePath"
        case image
        case current
    }

    private enum CurrentCodingKeys: String, CodingKey {
        case title
    }

    let id: Int
    let name: String
    let url: String
    let image: String
    let title: String

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = try? values.decode(Int.self, forKey: .id)
        let rawName = try? values.decode(String.self, forKey: .name)
        let rawUrl = try? values.decode(String.self, forKey: .url)
        let rawImage = try? values.decode(String.self, forKey: .image)

        let rawTitle: String?
        if let current = try? values.nestedContainer(keyedBy: CurrentCodingKeys.self, forKey: .current) {
            rawTitle = try? current.decode(String.self, forKey: .title)
        } else {
            rawTitle = nil
        }

        guard let id = rawId else {
            throw ChannelError.missingData
        }

        self.id = id
        self.name = rawName ?? ""
        self.url = rawUrl ?? ""
        self.image = rawImage ?? ""
        self.title = rawTitle ?? ""
    }

    init(from channel: Channel) {
        self.id = channel.id
        self.name = channel.name
        self.url = channel.url
        self.image = channel.image
        self.title = channel.title
    }

    // The keys must have the same name as the attributes of the Channel entity.
    var dictionaryValue: [String: Any] {
        [
            "id": id,
            "name": name,
            "url": url,
            "image": image,
            "title": title
        ]
    }

}
