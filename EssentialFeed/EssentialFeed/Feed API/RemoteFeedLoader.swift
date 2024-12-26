//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 25/12/24.
//
import Foundation

public protocol HTTPClient {
    func get(from url:URL, completion: @escaping (HTTPClientResult) -> Void)
}

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public final class RemoteFeedLoader {
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
    
    public enum Result: Equatable {
        case success ([FeedItem])
        case failure (Error)
    }
    
    public func load(completion:@escaping (Result) -> Void) {
        client.get(from:url) { result in
            switch result {
            case .success:
                completion(.failure(.invalidData))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
