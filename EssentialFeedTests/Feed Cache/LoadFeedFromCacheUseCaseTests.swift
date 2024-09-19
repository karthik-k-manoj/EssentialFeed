//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 19/09/24.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    // this test is already there in other save use case but that's a
    // coincidental duplication. In future we could load and save in different
    // types
    func test_init_doesNotMessageUponCreationUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load {  _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_retrievalError() {
        let (sut, store) = makeSUT()
        let retreivalError = anyNSError()
        let exp = expectation(description: "Wait for load completion")
        
        var receivedError: Error?
        sut.load { result in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Expeced failure, but got \(result) instead.")
            }
            
            exp.fulfill()
        }
        
        store.completeRetrieval(with: retreivalError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, retreivalError)
    }
    
//    func test_load_delviersNoImagesOnEmptyCache() {
//        let (sut, store) = makeSUT()
//        let exp = expectation(description: "Wait for load completion")
//        
//        var receivedImages: [FeedImage]
//        sut.load { result in
//            receivedImages = error
//            exp.fulfill()
//        }
//        
//        store.completeRetrieval(with: retreivalError)
//        
//        wait(for: [exp], timeout: 1.0)
//        
//        XCTAssertEqual(receivedError as NSError?, retreivalError)
//    }
    
    private func makeSUT(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: { currentDate })
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "", code: 0)
    }
}
