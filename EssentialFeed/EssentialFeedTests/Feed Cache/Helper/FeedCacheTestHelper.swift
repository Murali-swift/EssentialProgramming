//
//  FeedCacheTestHelper.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 19/01/25.
//

import Foundation
import EssentialFeed

func uniqueImageFeed() -> FeedImage {
    return FeedImage(id: UUID(), description: "Any", location: "Any", url: anyURL())
}

func uniqueImage() -> (model:[FeedImage],local:[LocalFeedImage]) {
    let items = [uniqueImageFeed(),uniqueImageFeed()]
    let localItems = items.map{LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    return (items,localItems)
}

extension Date {
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    
    func minusFeedCacheMAXAge() -> Date {
        return self.adding(days: -feedCacheMaxAgeInDays)
    }
    
    private func adding(days:Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

extension Date {
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
