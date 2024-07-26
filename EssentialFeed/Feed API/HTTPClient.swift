//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 24/07/24.
//

import Foundation

public enum HTTPClientResult {
    // success from the backend. It could be a response with 201, 201 (created), 202(accepted), 301 (not modified), 400, 500
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
