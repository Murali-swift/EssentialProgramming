//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Murali Nallusamy on 24/12/24.
//

import XCTest

class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}


class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doestNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
        XCTAssertNil(client.requestedURL)
    }
}
