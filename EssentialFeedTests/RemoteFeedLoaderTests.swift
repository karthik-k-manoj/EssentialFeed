//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 11/07/24.
//

import XCTest

class RemoteFeedLoader {
    
}

class HTTPCLient {
    var requestedURL: URL?
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPCLient()
        _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }

}
