
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
        sut.load()
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
