//
//  CacheFeedUseCasesTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 24/08/24.
//

import XCTest
import EssentialFeed

// Developing softwate is a social activity and often we must gather domain info from outside tech team
// technical or business decision we must gather adequate info about the req before we start to code
// we need conversation
// Requirements comes from business people and they are leading the conversation
// use cases are more technical in nature and developers start leading the conversation

// replace is two action delete and save new
// delete might fail
// deleting error course (sad path)
// saving error course (sad path)
// clarify caching requirements. make req more explicit. it is an iterative process
// we might find missing requ. Decision aren't final. to be able to adapt quickly and welcome
// requirement change aim for flexible sol. be ready so you don't have to get ready


/*
 FeedStore is a helper class representing the framework side to help us
 define the abstract interface the use case needs for it's collaborator, making sure
 not to leak framework details into Use Case
 */
/*
 this class adds production code test code. this is a different appraoch than making a spy class implement a protocol
 */

final class CacheFeedUseCasesTests: XCTestCase {
    // without invoking any behavior we want just by creating sut we to assert that we do not delete cache
    func test_init_doesNotMessageUponCreationUponCreation() {
        let (_, store) = makeSUT()
        /*
         To decouple app from framework details we don't let framework dictate the use case interface the use case needs
         we do by test driving the interfaces the Use case needs for it's collaborator, rather than defining the interface upfront to facilitate a specific framework impl
         */
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        
        sut.save(uniqueImageFeed().model) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()

        let deletionError = anyNSError()
        
        sut.save(uniqueImageFeed().model) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timeStamp = Date()
        let (sut, store) = makeSUT(currentDate: timeStamp)
        let items = uniqueImageFeed()
        
        sut.save(items.model) { _ in }
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items.local , timeStamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
 
        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().model) { receivedResults.append($0) }
                
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().model) { receivedResults.append($0) }
        
        sut = nil
        
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: { currentDate })
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion.")
        
        var receivedError: LocalFeedLoader.SaveResult?
        
        sut.save(uniqueImageFeed().model) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError??, expectedError, file: file, line: line)
    }
}
