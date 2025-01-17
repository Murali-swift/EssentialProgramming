//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 27/12/24.
//
import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}

class FeedItemsMapper {
    struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    private static var Ok_200: Int { return 200}
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem]
    {
        guard response.statusCode == Ok_200,  let root = try? JSONDecoder().decode(Root.self, from:data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
