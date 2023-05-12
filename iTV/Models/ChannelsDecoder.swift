//
//  ChannelDecoder.swift
//  iTV
//
//  Created by Яна Латышева on 12.05.2023.
//

import Foundation

struct ChannelsDecoder {
    let channelProperties: [ChannelProperties]

    init(from data: Data) {
        channelProperties = []
    }
}
