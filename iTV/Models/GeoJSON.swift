//
//  GeoJSON.swift
//  iTV
//
//  Created by Яна Латышева on 16.12.2022.
//

import Foundation

/** JSON feed **
 {
     "channels": [
         {
             "id": 10180,
             "name_ru": "Матч! Премьер",
             "url": "",
             "image": "https://assets.iptv2022.com/static/channel/10180/logo_256_1658736853.png",
             "current": {
                 "title": "Fonbet Кубок России. \"Урал\" - ЦСКА",
             },
         }
     ]
 }
 */

struct GeoJSON: Decodable {

    private enum RootCodingKeys: String, CodingKey {
        case channels
    }

    private(set) var channelPropertiesList = [ChannelProperties]()

    init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: RootCodingKeys.self)
        var channelsContainer = try rootContainer.nestedUnkeyedContainer(forKey: .channels)

        while !channelsContainer.isAtEnd {
            if let properties = try? channelsContainer.decode(ChannelProperties.self) {
                channelPropertiesList.append(properties)
            }
        }
    }
}
