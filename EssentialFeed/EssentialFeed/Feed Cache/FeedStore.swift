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
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}



