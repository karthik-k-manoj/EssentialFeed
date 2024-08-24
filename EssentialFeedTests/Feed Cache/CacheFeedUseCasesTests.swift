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


final class LocalFeedLoader {
    let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

/*
 FeedStore is a helper class representing the framework side to help us
 define the abstract interface the use case needs for it's collaborator, making sure
 not to leak framework details into Use Case
 */
class FeedStore {
    var deletedCachedFeedCallCount = 0
    
    func deleteCachedFeed() {
        deletedCachedFeedCallCount += 1
    }
}

final class CacheFeedUseCasesTests: XCTestCase {
    // without invoking any behavior we want just by creating sut we to assert that we do not delete cache
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        /*
         To decouple app from framework details we don't let framework dictate the use case interface the use case needs
         we do by test driving the interfaces the Use case needs for it's collaborator, rather than defining the interface upfront to facilitate a specific framework impl
         */
        XCTAssertEqual(store.deletedCachedFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        
        XCTAssertEqual(store.deletedCachedFeedCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
}
