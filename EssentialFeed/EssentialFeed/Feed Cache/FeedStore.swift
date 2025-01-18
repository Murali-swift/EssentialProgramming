//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 12/01/25.
//

import Foundation

public protocol FeedStore {
    typealias InsertionCompletion = (Error?) -> Void
    typealias DeleteCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}



