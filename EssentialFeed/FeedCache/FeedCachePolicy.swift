//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 23/09/24.
//

import Foundation

// entity are business model with identity
// value objects are business models without identity like a policy
// in this case policy has no identity which mean it can be static. just encapsultes just the rules

// Rules.

internal final class FeedCachePolicy {
    private init() {}
    
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxCacheAgeInDays: Int { 7 }
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return date < maxCacheAge
    }
}
