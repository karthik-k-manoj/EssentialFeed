//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 22/09/24.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageUponCreationUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_validateCache_deletesCachesOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "", code: 0)
    }
    
    private func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private func uniqueImageFeed() -> (model: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let local = models.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.imageURL)
        }
        
        return (models, local)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
