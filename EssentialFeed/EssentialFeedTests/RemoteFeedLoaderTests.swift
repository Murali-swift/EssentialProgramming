//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Murali Nallusamy on 24/12/24.
//

import XCTest

class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.get(from: URL(string: "https://www.google.com")!)
    }
}

class HTTPClient {
    static var shared = HTTPClient()
    
    func get(from url:URL) {}
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    override func get(from url: URL) {
        requestedURL = url
    }
}


class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doestNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        _ = RemoteFeedLoader()
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_reuestsDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let sut = RemoteFeedLoader()
        sut.load()
        XCTAssertNotNil(client.requestedURL)
    }
}
