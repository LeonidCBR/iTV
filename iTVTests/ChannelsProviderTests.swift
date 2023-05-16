//
//  ChannelsProviderTests.swift
//  iTVTests
//
//  Created by Яна Латышева on 16.05.2023.
//

import XCTest
@testable import iTV

final class ChannelsProviderTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var sut: ChannelsProvider!

    override func setUpWithError() throws {
        coreDataStack = try CoreDataStack(isEphemeral: true)
        sut = ChannelsProvider(with: coreDataStack)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    @MainActor
    func testChannelsProvider_FetchAllChannels() async throws {
        let bgContext = coreDataStack.newDerivedContext()
        try await bgContext.perform {
            let channel = Channel(context: bgContext)
            channel.id = 100
            channel.name = "Первый канал"
            channel.url = "http://mhd.iptv2022.com/p/index.m3u8"
            channel.image = "https://assets.iptv2022.com/static/logo.png"
            channel.title = "Информационный канал"
            channel.isFavorite = false
            let newchannel = Channel(context: bgContext)
            newchannel.id = 200
            newchannel.name = "MTV"
            newchannel.url = "http://mhd.iptv2022.com/mtv/index.m3u8"
            newchannel.image = "https://assets.iptv2022.com/static/mtv.png"
            newchannel.title = "Музыка"
            newchannel.isFavorite = true
            try bgContext.save()
        }

        let channels = try sut.fetchChannels(searchText: "", filter: .all)

        XCTAssertEqual(channels.count, 2)
        guard let firstChannel = channels.first(where: {$0.id == 100}) else {
            XCTFail("There is no channel with id=100.")
            return
        }
        XCTAssertEqual(firstChannel.name, "Первый канал")
        XCTAssertEqual(firstChannel.url, "http://mhd.iptv2022.com/p/index.m3u8")
        XCTAssertEqual(firstChannel.image, "https://assets.iptv2022.com/static/logo.png")
        XCTAssertEqual(firstChannel.title, "Информационный канал")
        XCTAssertEqual(firstChannel.isFavorite, false)

        guard let secondChannel = channels.first(where: {$0.id == 200}) else {
            XCTFail("There is no channel with id=200.")
            return
        }
        XCTAssertEqual(secondChannel.name, "MTV")
        XCTAssertEqual(secondChannel.url, "http://mhd.iptv2022.com/mtv/index.m3u8")
        XCTAssertEqual(secondChannel.image, "https://assets.iptv2022.com/static/mtv.png")
        XCTAssertEqual(secondChannel.title, "Музыка")
        XCTAssertEqual(secondChannel.isFavorite, true)
    }

}
