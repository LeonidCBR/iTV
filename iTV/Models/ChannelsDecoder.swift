//
//  ChannelDecoder.swift
//  iTV
//
//  Created by Яна Латышева on 12.05.2023.
//

import Foundation

/// A decoder of JSON data into a data model
struct ChannelsDecoder {
    let channelPropertiesList: [ChannelProperties]

    init(from data: Data) throws {
        do {
            // Decode the data and populate list of channels
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970
            let channelsFeed = try jsonDecoder.decode(ChannelsFeed.self, from: data)
            channelPropertiesList = channelsFeed.channelPropertiesList
        } catch {
            throw ChannelError.wrongDataFormat(error: error)
        }
    }

}
