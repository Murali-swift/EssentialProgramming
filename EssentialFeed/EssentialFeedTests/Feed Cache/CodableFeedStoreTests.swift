//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 23/01/25.
//

import XCTest
import EssentialFeed

class CodabelFeedStore {
    private struct Cache:Codable {
        let feeds: [LocalFeedImage]
        let timestamp: Date
    }
    private let storeURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("imageFeed.store")
    
    func retrieve(_ completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.feeds, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feeds: feed, timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let storeURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("imageFeed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
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
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = CodabelFeedStore()
        let exp = expectation(description: "wait for cache retrieval")
        
        
        sut.retrieve{firstResult in
            sut.retrieve{secondResult in
                switch (firstResult,secondResult) {
                case (.empty,.empty):
                    break
                default:
                    XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodabelFeedStore()
        let feed = uniqueImage().local
        let timeStamp: Date = Date()
        let exp = expectation(description: "wait for cache retrieval")
        
        sut.insert(feed, timestamp: timeStamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            
            sut.retrieve{result in
                switch result {
                case let .found(retrievedfeed, retrievedtimestamp):
                    XCTAssertEqual(retrievedfeed, feed)
                    XCTAssertEqual(retrievedtimestamp, timeStamp)
                default:
                    XCTFail("Expected found result with feed \(feed) and timestamp \(timeStamp), got \(result) instead")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
}
