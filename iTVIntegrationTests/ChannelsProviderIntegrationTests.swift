//
//  iTVIntegrationTests.swift
//  iTVIntegrationTests
//
//  Created by Яна Латышева on 11.05.2023.
//

import XCTest
@testable import iTV

final class ChannelsProviderIntegrationTests: XCTestCase {

    var sut: ChannelsProvider!


    // TODO: Download channels, parse it and check count.
    

    override func setUp() {
        sut = ChannelsProvider()
    }

    override func tearDown() {
        sut = nil
    }

    func testExample() throws {
        XCTFail("Implement test cases")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
