//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 15/07/24.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURl: URL
}

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
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
        client.get(from: url) { resultType in
            switch resultType {
            case .failure:
                completion(.failure(.connectivity))
            case let .success(data, _):
                if let _ = try? JSONSerialization.jsonObject(with: data) {
                    completion(.success([]))
                } else {
                    completion(.failure(.invalidData))
                }
            }
        }
    }
}
