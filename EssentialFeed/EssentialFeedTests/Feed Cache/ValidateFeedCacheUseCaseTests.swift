//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 19/01/25.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_,store) = makeSUT()
        XCTAssertEqual(store.receivedMessage, [])
    }
    
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completionRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteLessThanSevenDaysOldCache() {
        let feed = uniqueImage()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days:-7).adding(seconds: 1)
        let (sut,store) = makeSUT(currentDate: {fixedCurrentDate})
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timeStamp: lessThanSevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_validateCache_deletesSevenDaysOldCache() {
        let feed = uniqueImage()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimeStamp = fixedCurrentDate.adding(days:-7)
        let (sut,store) = makeSUT(currentDate: {fixedCurrentDate})
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timeStamp: sevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_deletesMoreThanSevenDaysOldCache() {
        let feed = uniqueImage()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days:-7).adding(seconds: -1)
        let (sut,store) = makeSUT(currentDate: {fixedCurrentDate})
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timeStamp: moreThanSevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteinvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        sut = nil
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    //MARK - Helpers
    private func makeSUT(currentDate: @escaping (() -> Date) = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        tractForMemortyLeaks(store,file: file, line: line)
        tractForMemortyLeaks(sut,file: file, line: line)
        return (sut,store)
    }
}

