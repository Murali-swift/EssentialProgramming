
//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 18/01/25.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_,store) = makeSUT()
        XCTAssertEqual(store.receivedMessage, [])
    }
    
    func test_load_requestCacheRetrival() {
        let (sut,store) = makeSUT()
        sut.load{_ in}
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut,store) = makeSUT()
        let retrievalError = anyNSError()
        
        expect(sut, toCompletewith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    func test_load_deliversNoImageonEmptyCache() {
        let (sut,store) = makeSUT()
        
        expect(sut, toCompletewith: .success([])) {
            store.completionRetrievalWithEmptyCache()
        }
    }
    
    func test_load_deliversCachedImnagesOnLessThanSevenDaysOld() {
        let (sut,store) = makeSUT()

        expect(sut, toCompletewith: .success([])) {
            store.completionRetrievalWithEmptyCache()
        }
    }
    
    func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
        let feed = uniqueImage()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days:-7).adding(seconds: 1)
        let (sut,store) = makeSUT(currentDate: {fixedCurrentDate})

        expect(sut, toCompletewith: .success(feed.model)) {
            store.completeRetrieval(with: feed.local, timeStamp: lessThanSevenDaysOldTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let feed = uniqueImage()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days:-7)
        let (sut,store) = makeSUT(currentDate: {fixedCurrentDate})

        expect(sut, toCompletewith: .success([])) {
            store.completeRetrieval(with: feed.local, timeStamp: lessThanSevenDaysOldTimeStamp)
        }
    }
    
    func test_load_hasNoSideEffectOnRetreivalError() {
        let (sut, store) = makeSUT()
        
        sut.load{_ in}
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load{_ in}
        store.completionRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let feed = uniqueImage()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days:-7).adding(seconds: 1)
        let (sut,store) = makeSUT(currentDate: {fixedCurrentDate})
        
        sut.load{_ in}
        store.completeRetrieval(with: feed.local, timeStamp: lessThanSevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_deleteCacheOnSevenDaysOldCache() {
        let feed = uniqueImage()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimeStamp = fixedCurrentDate.adding(days:-7)
        let (sut,store) = makeSUT(currentDate: {fixedCurrentDate})
        
        sut.load{_ in}
        store.completeRetrieval(with: feed.local, timeStamp: sevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }
    
    func test_load_deleteCacheOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImage()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days:-7).adding(seconds: -1)
        let (sut,store) = makeSUT(currentDate: {fixedCurrentDate})
        
        sut.load{_ in}
        store.completeRetrieval(with: feed.local, timeStamp: moreThanSevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        
        sut?.load { result in
            receivedResults.append(result)
        }
        
        sut = nil
        store.completionRetrievalWithEmptyCache()

        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    
    //MARK - Helpers
    private func makeSUT(currentDate: @escaping (() -> Date) = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        tractForMemortyLeaks(store,file: file, line: line)
        tractForMemortyLeaks(sut,file: file, line: line)
        return (sut,store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompletewith expectedResult: LocalFeedLoader.LoadResult, when action: ()-> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for load completion")
        
        sut.load() { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages,file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line:line)
            default:
                XCTFail("Expected result \(expectedResult), got: \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any domain", code: 0)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func uniqueImageFeed() -> FeedImage {
        return FeedImage(id: UUID(), description: "Any", location: "Any", url: anyURL())
    }
    
    private func uniqueImage() -> (model:[FeedImage],local:[LocalFeedImage]) {
        let items = [uniqueImageFeed(),uniqueImageFeed()]
        let localItems = items.map{LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
        return (items,localItems)
    }
}


private extension Date {
    func adding(days:Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
