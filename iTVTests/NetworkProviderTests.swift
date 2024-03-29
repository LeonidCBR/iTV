//
//  NetworkProviderTests.swift
//  iTVTests
//
//  Created by Яна Латышева on 11.05.2023.
//

import XCTest
@testable import iTV

final class NetworkProviderTests: XCTestCase {
    var sut: NetworkProvider!

    override func setUp() {
        let ephemeralConfig = URLSessionConfiguration.ephemeral
        ephemeralConfig.protocolClasses = [MockURLProtocol.self]
        let ephemeralSession = URLSession(configuration: ephemeralConfig)
        sut = NetworkProvider(urlSession: ephemeralSession)
    }

    override func tearDown() {
        sut = nil
        MockURLProtocol.stubResponse = nil
        MockURLProtocol.stubData = nil
        MockURLProtocol.error = nil
    }

    func testNetworkProvider_WhenGivenSuccessfullResponse_ReturnsSuccess() async throws {
        let testURL = URL(string: "https://localhost")!
        let testData =  Data("{\"status\":\"ok\"}".utf8)
        let testResponse = HTTPURLResponse(url: testURL,
                                           statusCode: 200,
                                           httpVersion: "1.1",
                                           headerFields: ["Content-Type": "application/json"])
        MockURLProtocol.stubResponse = testResponse
        MockURLProtocol.stubData = testData
        MockURLProtocol.error = nil
        let request = URLRequest(url: testURL)
        let data = try await sut.downloadData(with: request)
        XCTAssertEqual(data, testData)
    }

    func testNetworkProvider_WhenGivenSuccessfullResponse_ReturnsSuccess2() async throws {
        let testURL = URL(string: "https://localhost")!
        let testData = Data("{\"status\":\"ok\"}".utf8)
        let testResponse = HTTPURLResponse(url: testURL,
                                           statusCode: 200,
                                           httpVersion: "1.1",
                                           headerFields: ["Content-Type": "application/json"])
        MockURLProtocol.stubResponse = testResponse
        MockURLProtocol.stubData = testData
        MockURLProtocol.error = nil
        let data = try await sut.downloadData(withUrl: testURL)
        XCTAssertEqual(data, testData)
    }

    func testNetworkProvider_WhenGivenNoResponse_ReturnError() async {
        let testURL = URL(string: "https://localhost")!
        let testData = Data("{\"status\":\"ok\"}".utf8)
        MockURLProtocol.stubResponse = nil
        MockURLProtocol.stubData = testData
        MockURLProtocol.error = nil
        var didFailWithError: Error?
        do {
            _ = try await sut.downloadData(withUrl: testURL)
        } catch {
            didFailWithError = error
        }
        guard didFailWithError != nil else {
            XCTFail("A noResponse error should have been thrown but no error was thrown")
            return
        }
        guard let networkError = didFailWithError as? NetworkError else {
            XCTFail("An error type should be a ChannelError")
            return
        }
        guard case .noResponse = networkError else {
            XCTFail("A noResponse error should have been thrown but another error was thrown")
            return
        }
    }

    func testNetworkProvider_WhenGivenCode401_ReturnUnauthorizedError() async {
        let testURL = URL(string: "https://localhost")!
        let testData = Data("{\"status\":\"ok\"}".utf8)
        let testResponse = HTTPURLResponse(url: testURL,
                                           statusCode: 401,
                                           httpVersion: "1.1",
                                           headerFields: ["Content-Type": "application/json"])
        MockURLProtocol.stubResponse = testResponse
        MockURLProtocol.stubData = testData
        MockURLProtocol.error = nil
        var didFailWithError: Error?
        do {
            _ = try await sut.downloadData(withUrl: testURL)
        } catch {
            didFailWithError = error
        }
        guard didFailWithError != nil else {
            XCTFail("A unauthorized error should have been thrown but no error was thrown")
            return
        }
        guard let networkError = didFailWithError as? NetworkError else {
            XCTFail("An error type should be a ChannelError")
            return
        }
        guard case .unauthorized = networkError else {
            XCTFail("A unauthorized error should have been thrown but another error was thrown")
            return
        }
    }

    func testNetworkProvider_WhenGivenCode555_ReturnUnhandledError() async {
        let testURL = URL(string: "https://localhost")!
        let testData = Data("{\"status\":\"ok\"}".utf8)
        let testResponse = HTTPURLResponse(url: testURL,
                                           statusCode: 555,
                                           httpVersion: "1.1",
                                           headerFields: ["Content-Type": "application/json"])
        MockURLProtocol.stubResponse = testResponse
        MockURLProtocol.stubData = testData
        MockURLProtocol.error = nil
        var didFailWithError: Error?
        do {
            _ = try await sut.downloadData(withUrl: testURL)
        } catch {
            didFailWithError = error
        }
        guard didFailWithError != nil else {
            XCTFail("An unhandled error should have been thrown but no error was thrown")
            return
        }
        guard let networkError = didFailWithError as? NetworkError else {
            XCTFail("An error type should be a ChannelError")
            return
        }
        guard case let .unhandledError(statusCode) = networkError else {
            XCTFail("An unhandled error should have been thrown but another error was thrown")
            return
        }
        XCTAssertEqual(555, statusCode)
    }

}
