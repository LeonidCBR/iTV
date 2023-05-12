//
//  iTVIntegrationTests.swift
//  iTVIntegrationTests
//
//  Created by Яна Латышева on 11.05.2023.
//

import XCTest
@testable import iTV

final class IntegrationTests: XCTestCase {
    var sut: ChannelsProvider!

    override func setUp() {
        sut = ChannelsProvider()
    }

    override func tearDown() {
        sut = nil
    }

    func testExample() async throws {
        let channelsURL = URL(string: "http://limehd.online/playlist/channels.json")!
        let networkProvider = NetworkProvider()
        let channelsData = try await networkProvider.downloadData(withUrl: channelsURL)
        let channelsDecoder = try ChannelsDecoder(from: channelsData)
        let channelPropertiesList = channelsDecoder.channelPropertiesList
        XCTAssertGreaterThan(channelPropertiesList.count, 0)
    }

}
