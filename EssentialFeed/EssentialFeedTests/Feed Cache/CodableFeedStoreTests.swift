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
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        }
        catch {
            completion(.failure(error))
        }
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feeds: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        do {
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
        
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
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSut()
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSut()
        let feed = uniqueImage().local
        let timeStamp: Date = Date()
        
        insert(sut, feed, timeStamp)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timeStamp))
    }
    
    func test_retrieve_hasNoSideEffectOnNonEmptyCache() {
        let sut = makeSut()
        let feed = uniqueImage().local
        let timeStamp: Date = Date()
        
        insert(sut, feed, timeStamp)
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timeStamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSut(storeURL: storeURL)
        
        try! "invalidData".write(to: storeURL, atomically: true, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_insert_overridesPreviousInsertedCacheValues() {
        let sut = makeSut()
        
        let firstInsertionError = insert(sut, uniqueImage().local, Date())
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let latestFeed = uniqueImage().local
        let latestTimeStamp = Date()
        let latestInsertionError = insert(sut, latestFeed, latestTimeStamp)
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
        
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimeStamp))

    }
    
    func test_retrieve_hasNoSideEffectOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSut(storeURL: storeURL)
        
        try! "invalidData".write(to: storeURL, atomically: true, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    // - MARK: Helpers
    
    private func makeSut(storeURL: URL? = nil, file:StaticString = #file, line:UInt = #line) -> CodabelFeedStore {
        let sut = CodabelFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemortyLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    @discardableResult
    private func insert(_ sut: CodabelFeedStore, _ feed: [LocalFeedImage], _ timeStamp: Date, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "wait for cache retrieval")
        var insertionError: Error?
        sut.insert(feed, timestamp: timeStamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    private func expect(_ sut:CodabelFeedStore, toRetrieveTwice expectedResult: RetrievalCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut,toRetrieve: expectedResult,file: file,line: line)
        expect(sut,toRetrieve: expectedResult,file: file,line: line)
    }
    
    private func expect(_ sut:CodabelFeedStore, toRetrieve expectedResult: RetrievalCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for cache retrieval")

        sut.retrieve{retrievedResult in
            switch (expectedResult,retrievedResult) {
            case (.empty,.empty), (.failure, .failure):
                break
            case let (.found(expected),.found(retrieved)) :
                XCTAssertEqual(retrieved.feed, expected.feed,file: file,line: line)
                XCTAssertEqual(retrieved.timestamp, expected.timestamp,file: file,line: line)
            default:
                XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(expectedResult) and \(retrievedResult) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
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
