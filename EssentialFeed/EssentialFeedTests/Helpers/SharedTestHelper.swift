//
//  SharedTestHelper.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 19/01/25.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any domain", code: 0)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}
