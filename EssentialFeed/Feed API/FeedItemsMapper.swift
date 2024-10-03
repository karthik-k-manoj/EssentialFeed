//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 24/07/24.
//

import Foundation

// Just a namspace for static methods. It does two kind of mapping. One is JSON data to `Root`
// `RemoteFeedItem` to `FeedItem`
internal final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    private static var OK_200: Int { 200 }
    
    internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
