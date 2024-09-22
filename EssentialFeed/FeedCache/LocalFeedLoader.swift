//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 06/09/24.
//

import Foundation

// use cases encap application specific logic
// rules and polices can be represetned as business model and are app agnositc and framework and side-effects (across application)
public final class LocalFeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)
    private var maxCacheAgeInDays: Int {
        return 7
    }
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return currentDate() < maxCacheAge
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void)  {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed : [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure:
                self.store.deleteCachedFeed { _  in }
            case let .found(_, timestamp) where !self.validate(timestamp):
                self.store.deleteCachedFeed { _ in }
            case .empty, .found: break
            }
        }
    }
      
}
extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult
    
    // query should not have side effects
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModel()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}


private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map {  LocalFeedImage(id: $0.id, description: $0.description, location: $0.description, url: $0.imageURL) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModel() -> [FeedImage] {
        map {  FeedImage(id: $0.id, description: $0.description, location: $0.description, imageURL: $0.url) }
    }
}
