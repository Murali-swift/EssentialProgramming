//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 12/01/25.
//
import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(feeds: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(feeds, with: completion)
            }
        }
    }
    
    private func cache(_ items:[FeedItem], with completion: @escaping (Error?) -> Void) {
        store.insert(items, timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}
