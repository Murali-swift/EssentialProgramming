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
    
    static func map(_ data:Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == Ok_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from:data)
        return root.items.map{$0.item}
    }
}
