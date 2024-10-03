//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Karthik K Manoj on 22/09/24.
//

import Foundation

func anyNSError() -> NSError {
    NSError(domain: "", code: 0)
}

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}
