//
//  ChannelDecoder.swift
//  iTV
//
//  Created by Яна Латышева on 12.05.2023.
//

import Foundation

struct ChannelsDecoder {
    let channelPropertiesList: [ChannelProperties]

    init(from data: Data) throws {
        do {
            // Decode the JSON data into a data model.
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970
            let geoJSON = try jsonDecoder.decode(GeoJSON.self, from: data)
            channelPropertiesList = geoJSON.channelPropertiesList
        } catch {
            throw ChannelError.wrongDataFormat(error: error)
        }
    }

}
