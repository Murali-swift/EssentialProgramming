//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 26/01/25.
//
import Foundation

public class CodabelFeedStore: FeedStore {
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image:LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private struct Cache:Codable {
        private let feeds: [CodableFeedImage]
        let timestamp: Date
        
        init(feeds: [CodableFeedImage], timestamp: Date) {
            self.feeds = feeds
            self.timestamp = timestamp
        }
        
        var localFeed: [LocalFeedImage] {
            return feeds.map { $0.local }
        }
    }
    
    private let storeURL: URL
    
    private let queue = DispatchQueue(label: "\(CodableFeedImage.self) Queue", qos: .userInitiated, attributes: .concurrent)
    
    public init(storeURL:URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }
            do {
                let decoder = JSONDecoder()
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
            }
            catch {
                completion(.failure(error))
            }
        }
       
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        queue.async {
            let encoder = JSONEncoder()
            let cache = Cache(feeds: feed.map(CodableFeedImage.init), timestamp: timestamp)
            let encoded = try! encoder.encode(cache)
            do {
                try encoded.write(to: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            guard (try? Data(contentsOf: storeURL)) != nil else {
                completion(nil)
                return
            }
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(nil)
                
            } catch {
                completion(error)
            }
        }
    }
}
