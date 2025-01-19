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
    public typealias LoadResult = LoadFeedResult

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(_ completion:@escaping((LoadResult) -> Void)) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case let .failure(error):
                store.deleteCachedFeed { _ in }
                completion(.failure(error))
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
            case .found:
                store.deleteCachedFeed { _ in }
                completion(.success([]))
            case .empty:
                completion(.success([]))
            }
        }
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
    
    private func validate(_ timestamp: Date) -> Bool {
        let calender = Calendar(identifier: .gregorian)
        guard let maxCacheAge = calender.date(byAdding: .day, value: 7, to: timestamp) else {
            return false
        }
        
        return currentDate() < maxCacheAge
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

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map{FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
