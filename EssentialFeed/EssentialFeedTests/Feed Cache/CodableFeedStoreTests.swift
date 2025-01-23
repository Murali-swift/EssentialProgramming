//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 23/01/25.
//

import XCTest
import EssentialFeed

class CodabelFeedStore {
    func retrieve(_ completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodabelFeedStore()
        let exp = expectation(description: "wait for cache retrieval")
        
        sut.retrieve{result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
