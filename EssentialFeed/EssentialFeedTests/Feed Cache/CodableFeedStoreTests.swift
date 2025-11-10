//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 23/01/25.
//

import XCTest
import EssentialFeed

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
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://strore-url")!
        let sut = makeSut(storeURL: invalidStoreURL)
        let feed = uniqueImage().local
        let timestamp: Date = Date()
        
        let insertionError = insert(sut, feed, timestamp)
        XCTAssertNotNil(insertionError, "Expected to fail insertion")
    }
    
    func test_retrieve_hasNoSideEffectOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSut(storeURL: storeURL)
        
        try! "invalidData".write(to: storeURL, atomically: true, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        let sut = makeSut()
        
        let deletion = deleteCache(from:sut)
        
        XCTAssertNil(deletion, "Expected empty cache deltion to succeed ")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedData() {
        let sut = makeSut()
        insert(sut, uniqueImage().local, Date())
        
        let deletion = deleteCache(from:sut)
        
        XCTAssertNil(deletion, "Expected empty cache deltion to succeed ")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSut()
        var completedOperationsInOrder = [XCTestExpectation] ()
        
        let op1  = expectation(description: "Operation 1")
        sut.insert(uniqueImage().local, timestamp: Date()) {_ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2  = expectation(description: "Operation 2")
        sut.deleteCachedFeed {_ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3  = expectation(description: "Operation 3")
        sut.insert(uniqueImage().local, timestamp: Date()) {_ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completedOperationsInOrder, [op1,op2,op3], "Expected side-effects to run serially but operation finished in wrong order")
    }
    
//    func test_delete_deliversErrorOnDeletionError() {
//        let noDeletePermissionURL = cacheDirection()
//    }
    
    // - MARK: Helpers
    
    
    private func makeSut(storeURL: URL? = nil, file:StaticString = #file, line:UInt = #line) -> FeedStore {
        let sut = CodabelFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemortyLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    @discardableResult
    private func insert(_ sut: FeedStore, _ feed: [LocalFeedImage], _ timeStamp: Date, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "wait for cache retrieval")
        var insertionError: Error?
        sut.insert(feed, timestamp: timeStamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
    
    private func cacheDirection() {
        
    }
    
    private func expect(_ sut:FeedStore, toRetrieveTwice expectedResult: RetrievalCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut,toRetrieve: expectedResult,file: file,line: line)
        expect(sut,toRetrieve: expectedResult,file: file,line: line)
    }
    
    private func expect(_ sut:FeedStore, toRetrieve expectedResult: RetrievalCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
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
