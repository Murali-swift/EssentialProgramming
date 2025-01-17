//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 18/01/25.
//
import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
