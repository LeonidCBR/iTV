//
//  ChannelsProviderTests.swift
//  iTVTests
//
//  Created by Яна Латышева on 17.12.2022.
//

import XCTest
@testable import iTV

class ChannelsProviderTests: XCTestCase {

    var sut: ChannelsProvider!

    override func setUp() {
        sut = ChannelsProvider.shared
    }

    override func tearDown()  {
        sut = nil
    }

    func testParseChannelPropertiesList() throws {
        let bundle = Bundle(for: ChannelsProviderTests.self)
        let jsonUrl = bundle.url(forResource: "channels", withExtension: "json")!
        let jsonData = try Data(contentsOf: jsonUrl)
        let channels = try sut.parseChannelPropertiesList(from: jsonData)
        XCTAssertEqual(channels.count, 469)
        let channel = channels[2]
        XCTAssertEqual(channel.id, 105)
        XCTAssertEqual(channel.name, "Первый канал")
        XCTAssertEqual(channel.url, "http://mhd.iptv2022.com/p/FVfEP3aeAmDPchj6nJYepQ,1669209428/streaming/1kanalott/324/1/index.m3u8")
        XCTAssertEqual(channel.image, "https://assets.iptv2022.com/static/channel/105/logo_256_1655386697.png")
        XCTAssertEqual(channel.title, "Информационный канал")
    }

}
