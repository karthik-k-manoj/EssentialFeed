//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Karthik K Manoj on 02/08/24.
//

import Foundation

/*
 improvement limiting API we have access to it. created protocol that has the matching interface in Foundation
 for sole purpose of purpose for testing. Valid solutions. A little improvmenet. improved our test but production code got complex
*/

// This is infact an adapter which adapts URLSession.dataTask completion handler
// to  ` @escaping (HTTPClientResult) -> Void`
// This is tested so that we are gauranteed that we are actually using the framework correctly
// this adapter during test uses mock or test double (such as URLProtocolStub)
public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValueRepresentaion: Error {}
     
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
                // empty data representation is a valid representation. HTTP 204 Status code
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValueRepresentaion()))
            }
        }
        .resume()
    }
}
