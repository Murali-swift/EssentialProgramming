//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 22/01/25.
//

import Foundation

internal final class FeedCachePolicy {
    private static let calender = Calendar(identifier: .gregorian)
    
    private init() {}

    private static var maxCacheAgeInDays: Int {
        return 7
    }
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calender.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return date < maxCacheAge
    }
}
