//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Murali Nallusamy on 24/12/24.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doestNotRequestDataFromURL() {
        let (_,client) = makeSut()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_reuestsDataFromURL() {
        let url = URL(string: "https://www.yahoo.com")!
        let (sut,client) = makeSut(url: url)
        sut.load()
        XCTAssertEqual(client.requestedURLs,[url])
    }
    
    func test_loadTwice_reuestsDataFromURL() {
        let url = URL(string: "https://www.yahoo.com")!
        let (sut,client) = makeSut(url: url)
        sut.load()
        sut.load()
        XCTAssertEqual(client.requestedURLs,[url,url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSut()
        client.error = NSError(domain: "Test", code: 0)
        var capturedErrors= [RemoteFeedLoader.Error]()
        sut.load {capturedErrors.append($0)}
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    //MARK - Helpers
    private func makeSut(url : URL = URL(string: "https://www.google.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var error: Error?
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            if let error {
                completion(error)
            }
            requestedURLs.append(url)
        }
    }
}
