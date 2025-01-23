//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 23/01/25.
//

import XCTest
import EssentialFeed

class CodabelFeedStore {
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image:LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private struct Cache:Codable {
        private let feeds: [CodableFeedImage]
        let timestamp: Date
        
        init(feeds: [CodableFeedImage], timestamp: Date) {
            self.feeds = feeds
            self.timestamp = timestamp
        }
        
        var localFeed: [LocalFeedImage] {
            return feeds.map { $0.local }
        }
    }
    
    private let storeURL: URL
    
    init(storeURL:URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(_ completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feeds: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSut()
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
        let sut = makeSut()
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
        let sut = makeSut()
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
    
    // - MARK: Helpers
    
    private func makeSut(file:StaticString = #file, line:UInt = #line) -> CodabelFeedStore {
        let sut = CodabelFeedStore(storeURL: testSpecificStoreURL())
        trackForMemortyLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func setupEmptyStoreState() {
        delteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        delteStoreArtifacts()
    }
    
    private func delteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
