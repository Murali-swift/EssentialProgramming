//
//  XCTestCase+MemoryLeakCheck.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 29/12/24.
//

import XCTest

extension XCTestCase {
    func tractForMemortyLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocation.Potential memory leak",file: file, line: line)
        }
    }
}
