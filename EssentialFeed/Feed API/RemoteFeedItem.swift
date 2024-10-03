//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 06/09/24.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
