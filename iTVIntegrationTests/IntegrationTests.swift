//
//  iTVIntegrationTests.swift
//  iTVIntegrationTests
//
//  Created by Яна Латышева on 11.05.2023.
//

import XCTest
@testable import iTV

final class IntegrationTests: XCTestCase {

    func testAPI() async throws {
        let networkProvider = NetworkProvider()
        let channelsData = try await networkProvider.downloadData(
            withUrl: ChannelsFeed.channelsURL)
        let channelsDecoder = try ChannelsDecoder(from: channelsData)
        let channelPropertiesList = channelsDecoder.channelPropertiesList
        XCTAssertGreaterThan(channelPropertiesList.count, 0)
    }

}
