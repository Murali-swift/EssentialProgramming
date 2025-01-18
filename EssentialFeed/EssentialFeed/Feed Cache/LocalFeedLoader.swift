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
    public typealias SaveResult = Error?
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load() {
        store.retrieve()
    }
    
    public func save(feeds: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(feeds, with: completion)
            }
        }
    }
    
    private func cache(_ feed:[FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocalFeed(), timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocalFeed() -> [LocalFeedImage] {
        return map{LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
