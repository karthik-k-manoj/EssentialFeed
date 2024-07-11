//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 11/07/24.
//

import XCTest

class RemoteFeedLoader {
    func load() {
        // Here we have two responsibilities. One to locate the shared instance
        // and another to invoke this method. Using shared instance which exact
        // instance I am talking but it doesn't need to know. If we inject our client
        // we have more control over code.
        HTTPCLient.shared.get(from: URL(string: "http://a-url.com")!)
    }
}

class HTTPCLient {
    static var shared = HTTPCLient()
    
    var requestedURL: URL?
    
    func get(from url: URL) {
        
    }
}

class HTTPClientSpy: HTTPCLient {
    // This is test logic
    override func get(from url: URL) {
        requestedURL = url
    }
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPCLient.shared = client
        _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPCLient.shared = client
        let sut = RemoteFeedLoader()
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }

}
