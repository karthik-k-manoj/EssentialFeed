//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 11/07/24.
//

import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load() {
        /* Here we have two responsibilities. One to locate the shared instance
         and another to invoke this method. Using shared instance which exact
         instance I am talking but it doesn't need to know. If we inject our client
         we have more control over code.
        */
        client.get(from: URL(string: "http://a-url.com")!)
    }
}

/*But here we open the possibility for other classes to hear from HTTPClient which
 is not really what we need. We have made `shared` as global mutable state just to
 enable our test logic. Nothing wrong with subclass but there is better approach
 such as composition. To use composition we inject this type into `RemoteFeedLoader`
 
 This is an abstract class but in Swift we have protocol to define a interface like this
*/
protocol HTTPClient {
    func get(from url: URL)
}

/*Spy captures value. `HTTPClientSpy` is just an implementation of `HTTPClient` rather than a subtype of `HTTPClient` Setup is also simpler in this case. We don't need to inject a shared instance and clients
 do not need to locate and it can just whatever is given to it.
 */

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    // This is test logic
    func get(from url: URL) {
        requestedURL = url
    }
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }

}
