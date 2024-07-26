//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 26/07/24.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
