//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 25/12/24.
//
import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
//    public enum Result: Equatable {
//        case success ([FeedItem])
//        case failure (Error)
//    }
//    
   public typealias Result = LoadFeedResult<Error>
    
    public func load(completion:@escaping (Result) -> Void) {
        client.get(from:url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success(data, response):
                completion(FeedItemsMapper.map(data, response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
    
 
}


