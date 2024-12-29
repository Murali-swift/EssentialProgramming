//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 27/12/24.
//
import Foundation

class FeedItemsMapper {
    struct Root: Decodable {
        let items: [Item]
        var feed: [FeedItem] { items.map{$0.item}}
    }

    struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    private static var Ok_200: Int { return 200}
    
    static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result
    {
        guard response.statusCode == Ok_200,  let root = try? JSONDecoder().decode(Root.self, from:data) else {
            return .failure(.invalidData)
        }
        
        return .success(root.feed)
    }
}
