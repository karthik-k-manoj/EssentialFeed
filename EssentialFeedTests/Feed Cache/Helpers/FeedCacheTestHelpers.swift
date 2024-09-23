//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 22/09/24.
//

import Foundation
import EssentialFeed
 
func uniqueImage() -> FeedImage {
    FeedImage(id: UUID(), description: "any", location: "any", imageURL: anyURL())
}

 func uniqueImageFeed() -> (model: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map {
        LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.imageURL)
    }
    
    return (models, local)
}

// test specific tiny DSL to decouple test from implementation detail (calendar logic)
extension Date {
    func minusFeedCacheMaxAge() -> Date {
         adding(days: -7)
    }
    
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
