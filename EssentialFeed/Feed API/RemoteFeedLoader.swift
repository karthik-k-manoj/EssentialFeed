//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 15/07/24.
//

import Foundation


public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    // private let decoder: DecoderProtocol
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    /* Do you think for the same instance the client of `RemoteFeedLoader` would request different URLs
      Looking at `FeedLoader` method `load(completion:)` This means we could load it from URL, load it
     from cache. URL is a detail of the implementation of the RemoteFeedLoader`. It should not be part of
     the `load` interface
     */
    
    public func load(completion: @escaping (Result) -> Void) {
        /* Here we have two responsibilities. One to locate the shared instance
         and another to invoke this method. Using shared instance which exact
         instance I am talking but it doesn't need to know. If we inject our client
         we have more control over code.
        */
        /*
         We don't know what the URL it could be. We could have different enviornments such as
         dev, stage, uat. `RemoteFeedLoader` does not need to provenace of this data. It could
         given to it. So we can inject it.
         */
        
        /*
         We may have retain cycle here depending on how the client is created.
         `RemoteFeedLoader` own `HTTPClient`.
         `HTTPClient` has an escaping closure so it might be stored or called later (depending on how it is implemented)
    
         */
        /*
         here even though closure is not holding a strong reference. We are
         making it hold weak reference so that we check for nil. If it is not nil
         then we proceed.
         */
        
        /*
         we are conditioned to think about the classes we are building and not the collaborator. It could be a singleton whose lifetime we are not sure of
         */
        client.get(from: url) { [weak self] resultType in
            guard self != nil else { return }
            
            switch resultType {
            case .failure:
                completion(.failure(.connectivity))
            case let .success(data, response):
                completion(FeedItemsMapper.map(data, from: response))
            }
        }
    }
}
