//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 30/07/24.
//

import XCTest
import EssentialFeed

// We want all test method to run in isolation and as a group. if one test fails then
// all reason should be in each test method.

// pass in integration and not pass in isolation

// above can checked by randomizing to guarantee there is no order dependency

// if fewer tests no need for parallel testing

// code coverage means lines of code and not checking all behaviour

// code coverage is side effect of TDD but that's not the goal

// but to have confidence that we test the behaviour, and that

// we are free to change the code, being agile, prevent bugs

// if code coverage slows down the process then we will disable it

// add some end to end test in integration checking if agreed to contract

// a dev /test backend env allows us to run end-end-tests without the fear of unwanted side-effects in production

// In our exp a we cannot have test server. If not then we can
// create own.

// alternatively if there's any backend env, we can create test account with pre-populdated data. Make sure to create one account per app. So other app changes are not affecting our test result


final class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_getFromURL_failsOnAllNilValues() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    }
    
    func test_getFromURL_failsOnInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPResponse()
        let receivedValues = resultValuesFor(data: data, response: response, error: nil)
    
        XCTAssertEqual(receivedValues?.data , data)
        XCTAssertEqual(receivedValues?.response.url , response.url)
        XCTAssertEqual(receivedValues?.response.statusCode , response.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPResponse()
        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data , emptyData)
        XCTAssertEqual(receivedValues?.response.url , response.url)
        XCTAssertEqual(receivedValues?.response.statusCode , response.statusCode)
    }

//    func test_getFromURL_performsGETRequestWithURL() {
//        let url = anyURL()
//        let exp = expectation(description: "Wait for request")
//
//        URLProtocolStub.observeRequests { request in
//            XCTAssertEqual(request.url, url)
//            XCTAssertEqual(request.httpMethod, "GET")
//            exp.fulfill()
//        }
//
//        makeSUT().get(from: anyURL()) { _ in }
//
//        wait(for: [exp], timeout: 1.0)
//    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        
        XCTAssertEqual((receivedError as NSError?)?.domain, requestError.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, requestError.code)
    }
    
    // Later we can make this return type to be `HTTPClient` so we can protect from test from impl details later
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
      //  trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        var receivedError: Error?
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: anyURL()) { result in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        return receivedError
    }
    
    private func resultValuesFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        var receivedValues: (data: Data, response: HTTPURLResponse)?
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: anyURL()) { result in
            switch result {
            case let .success(data, response):
                receivedValues = (data, response)
            default:
                XCTFail("Expected success, got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        return receivedValues
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private func anyData() -> Data {
        Data("anyData".utf8)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "", code: 0)
    }
    
    private func anyHTTPResponse() -> HTTPURLResponse {
         HTTPURLResponse(url: anyURL(), statusCode: 0, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    
    private class URLProtocolStub : URLProtocol {
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
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
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

