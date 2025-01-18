//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 18/01/25.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    typealias FeedData = (items: [LocalFeedImage], timestamp: Date)
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private var deletionCompletions = [DeleteCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private(set) var receivedMessage = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        deletionCompletions.append(completion)
        receivedMessage.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: NSError, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index:Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertionSuccessfully(at index:Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessage.append(.insert(feed, timestamp))
    }
    
    func completeInsertion(with error: NSError, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func retrieve() {
        receivedMessage.append(.retrieve)
    }
}
