//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 26/07/24.
//

import Foundation

/*
 We are making all these just for the test, generic type, type constraints, associated type. All complicates the system just because of the test. Production has no requirement to be `Equatable` but this is a working solutions. we need to find a
 better solution.
 
 We've changed a bunch of type definitions in the production module and test target is still
 compiling fine and tests are passing with no changes needed. Kudos to swift type
 inference here.
 
 */

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

/*
Older Swift versions can't resolve the Swift.Error protocol for a generic type directly (the generic constraint requires a type that conforms to Swift.Error but Swift.Error doesn't conform to Swift.Error
because protocols don't conform to themselves). You'd get an error such as "Type 'Swift.Error' does not conform to protocol 'Swift.Error'" -
that's why we'd need the associatedtype.

If you're using the latest Swift versions, that won't be necessary because they added a special case for Swift.Error to conform to itself: https://github.com/apple/swift/pull/20629

public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

extension LoadFeedResult where Error: Equatable {}
 
 */

// feature module doesn't know about low level detail
// domain specific feature may be later 
public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

