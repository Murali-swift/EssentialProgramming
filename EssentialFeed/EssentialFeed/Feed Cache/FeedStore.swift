//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 12/01/25.
//

import Foundation

public enum RetrievalCachedFeedResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure( Error)
}

public protocol FeedStore {
    typealias InsertionCompletion = (Error?) -> Void
    typealias DeleteCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievalCachedFeedResult) -> Void
    
    /// The compleition handler can be invoked in any thread
    /// Clients are responsible to dispatch to appropriate threads, if needed
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    /// The compleition handler can be invoked in any thread
    /// Clients are responsible to dispatch to appropriate threads, if needed
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    /// The compleition handler can be invoked in any thread
    /// Clients are responsible to dispatch to appropriate threads, if needed
    func retrieve(completion: @escaping RetrievalCompletion)
}



