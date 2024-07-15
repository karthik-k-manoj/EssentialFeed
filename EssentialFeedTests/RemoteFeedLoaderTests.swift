//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 11/07/24.
//

import XCTest
import EssentialFeed
/*
 Lessons learned
 1) We don't need to conform the `FeedLoader` protocol at the start itself. We can test drive the implementation
    and when we are ready to compose we can bring `FeedLoader`
 
 2) `HTTPClient` has no reason to be a singleton or a shared instance aprt from the convenience to locate the
    instance directly. To justify a singleton we neeed to have good reason. We need only one instance of `HTTPClient`
 and there is no reason we need only one instance of it.
 
 3) `RemoteFeedLoader` does not need to locate or instantiate the `HTTPClient` instance.
    Instead we can make our more modular by injecting the HTTPClient as a dependency. It creates a strong depedency i.e `RemoteFeedLoader`
    cannot be created without an instance of `HTTPClient`. However using a singleton directly
    does not enforce this. A client wouldn't even know if such a dependecy exists. This is considered an anti-pattern.
    There are better way to deal with this problem. Example dependency injection. We confrom to OCP
    principle. By injecting the dependency we keep our code modular. If we locate or create our collaborator
    then we introduce tight coupling between the modules.
    Responsibility of locating and injecting the collaborator will be moved to a composer module (e.g., Main),
    so we can focus only on passing messages between the other components.
 
 4) `HTTPClient` does not need to be a class. It just a contract defining which external functionality the
    `RemoteFeedLoader` needs so protocpl is more suitable way to define it. The benefit of creating it as a protocol
    is that we don't need to create a new type. We can use easily create an extension on `URLSession`, Alamofire`.
    By creating a clean separation with protocol, we made the `RemoteFeedLoader` more flexible, open for extension and more testable.
 
 5) Refactoring backed up test is a very very powerful tool. By having the test you reduce the risk a fear of changing.
 */

/*But here we open the possibility for other classes to hear from HTTPClient which
 is not really what we need. We have made `shared` as global mutable state just to
 enable our test logic. Nothing wrong with subclass but there is better approach
 such as composition. To use composition we inject this type into `RemoteFeedLoader`
 
 This is an abstract class but in Swift we have protocol to define a interface like this
*/


/*Spy captures value. `HTTPClientSpy` is just an implementation of `HTTPClient` rather than a subtype of `HTTPClient`
 Setup is also simpler in this case. We don't need to inject a shared instance and clients
 do not need to locate and it can just whatever is given to it.
 */

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        
        // This is test logic
        func get(from url: URL) {
            requestedURLs.append(url)
        }
    }
}
