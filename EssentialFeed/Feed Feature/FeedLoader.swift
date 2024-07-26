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

public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}
 
// feature module doesn't know about low level detail
// domain specific feature may be later 
protocol FeedLoader {
    associatedtype Error: Swift.Error
    
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
