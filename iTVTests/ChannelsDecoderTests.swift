//
//  ChannelsProviderTests.swift
//  iTVTests
//
//  Created by Яна Латышева on 17.12.2022.
//

import XCTest
@testable import iTV

class ChannelsDecoderTests: XCTestCase {

    func testChannelsDecoder_WhenGivenValidData_ReturnChannelPropertiesList() throws {
        let bundle = Bundle(for: ChannelsDecoderTests.self)
        let jsonURL = bundle.url(forResource: "channels", withExtension: "json")!
        let channelsData = try Data(contentsOf: jsonURL)
        let channelsDecoder = try ChannelsDecoder(from: channelsData)
        let channels = channelsDecoder.channelPropertiesList
        guard channels.count == 469 else {
            XCTFail("It has been got \(channels.count) channels instead of 469")
            return
        }
        let channel = channels[2]
        XCTAssertEqual(channel.id, 105)
        XCTAssertEqual(channel.name, "Первый канал")
        XCTAssertEqual(channel.url,
                       "http://mhd.iptv2022.com/p/FVfEP3aeAmDPchj6nJYepQ,1669209428"
                       + "/streaming/1kanalott/324/1/index.m3u8")
        XCTAssertEqual(channel.image,
                       "https://assets.iptv2022.com/static/channel/105/logo_256_1655386697.png")
        XCTAssertEqual(channel.title, "Информационный канал")
    }

    func testPerformanceExample() throws {
        measure {
            let bundle = Bundle(for: ChannelsDecoderTests.self)
            let jsonURL = bundle.url(forResource: "channels", withExtension: "json")!
            if let channelsData = try? Data(contentsOf: jsonURL),
               let channelsDecoder = try? ChannelsDecoder(from: channelsData) {
                _ = channelsDecoder.channelPropertiesList
            }
        }
    }

}
