//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 30/07/24.
//

import XCTest
import EssentialFeed

/*
 improvement limiting API we have access to it. created protocol that has the matching interface in Foundation
 for sole purpose of purpose for testing. Valid solutions. A little improvmenet. improved our test but production code got complex
*/

// This is infact an adapter which adapts URLSession.dataTask completion handler
// to  ` @escaping (HTTPClientResult) -> Void`
// This is tested so that we are gauranteed that we are actually using the framework correctly
// this adapter during test uses mock or test double (such as URLProtocolStub)
class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }
        .resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_performsGETRequestWithURL() {
        URLProtocolStub.startInterceptingRequest()
        
        let url = URL(string: "http://any-url.com")!
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        URLSessionHTTPClient().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
        
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequest()
        
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(receviedError as NSError):
                XCTAssertEqual(receviedError.code, error.code)
                XCTAssertEqual(receviedError.domain, error.domain)
                
            default:
                XCTFail("Expected failure with error \(error), \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        URLProtocolStub.stopInterceptingRequest()
    }
    
    private class URLProtocolStub : URLProtocol {
        var receivedURLs = [URL]()
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func observeRequests(_ observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            stub = nil
            requestObserver = nil
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }
        
        // we can handle the request and our responbility to complete with success or failure
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // will get crash as this is abstract classs
        override func stopLoading() {}
    }
    
    // subclassing. often dangerous, we don't own their class. If we start mocking class we don't
    // we are making good assumptions. Working solutions so we commit
    // problem with those tests mocking class is test coupled with private implementation detail
    // everytime we want to refactor the code then test break. tests are checking the exact impl. But we need to check the behaviour of the production code. Since test broke because we didn't call resume.
}

