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
 
 Shijula :
 */

final class RemoteFeedLoaderTests: XCTestCase {
    
    // Test what happens when we don't call a method
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // Test what happens when we call the method once
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    // Test what happens when we call the method twice
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    // This is a domain specific error connectivity due to
    // client error (cannot connect to network)
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.connectivity)) {
            let clientError = NSError(domain: "Test", code: 1)
            client.complete(with: clientError)
        }
    }
    
    // This is a domain specific error invalid data due to
    // non 200 http response
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }
    
    func test_load_deliversFeedItemOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([])) {
            let json = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
         
        expect(sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData)) {
            let invalidJSON = Data("invalid.json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    // happy path
    func test_loadDeliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://a-url.com")!
        )
        
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "http://a-url.com")!
        )
        
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWithResult: .success(items)) {
            let jsonData = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: jsonData)
        }
    }
    
    /*
     In most cases we do not want the object that made the method call
     with a completion closure to be called when the object is deallocated
     that's one of the reason we need we use `guard self != nil else { return }`
     
     We left a documentation that this is for some reason. Soft documenting. We are checking. We are checking the behaviour
     
     We also do the inverse. When the object is deallocated then this happens.
     This is problem with asycnhronous code.
     */
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        // Given
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader?
        sut = RemoteFeedLoader(url: url, client: client)
        
        var isCompletionCalled = false
        // When
        sut?.load { _ in
            isCompletionCalled = true
        }
        
        sut = nil
        
        client.complete(withStatusCode: 200)
        
        // Then
        XCTAssertEqual(isCompletionCalled, false)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        
        // we are unwrapping it to get into the details due to which we have a
        // more test code but we simpify production code because it was a good trade off
        // we are also checking that completion closure was called only once and also checking the values inside. But later if you have the requirement code in the production to handle generics then you can do it else no. Passing test and no warning so commit even though we have to remove generics and type constraints
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                // This is the trade off because of using generic error.
                /*
                 Sometimes we need to make tough decision to protect our abstraction from implementation details
                 In this case it is still not clear to us if a domain specific error is necessary in the high level Feed feature module, so we prefer to use `Swift.Error` protocol for now.
                 */
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                 XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) git \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        var completions = [(Error) -> Void]()
        
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        // This is test logic
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            
            messages[index].completion(.success(data, response))
        }
    }
}

/*
 follow the same principle as TDD. make it work, make it right, make it fast`. We made it work. We were able to conform but we can improve the implementation.
 
 we need to have another goal now to get rid of `Equatable`
 
 We will not compare the `Result` value type as a whole, instead unwrap the inner value
 and compare the result
 */
