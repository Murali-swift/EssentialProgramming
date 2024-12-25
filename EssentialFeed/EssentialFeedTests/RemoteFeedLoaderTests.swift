//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Murali Nallusamy on 24/12/24.
//

import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL
    init(url: URL = URL(string: "https://www.google.com")!, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    func load() {
        client.get(from:url)
    }
}

protocol HTTPClient {
    func get(from url:URL)
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func get(from url: URL) {
        requestedURL = url
    }
}


class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doestNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_reuestsDataFromURL() {
        let url = URL(string: "https://www.yahoo.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        sut.load()
        XCTAssertEqual(client.requestedURL,url)
    }
}
