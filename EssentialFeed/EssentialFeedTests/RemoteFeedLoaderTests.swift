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
        sut.load(){_ in }
        XCTAssertEqual(client.requestedURLs,[url])
    }
    
    func test_loadTwice_reuestsDataFromURL() {
        let url = URL(string: "https://www.yahoo.com")!
        let (sut,client) = makeSut(url: url)
        sut.load(){_ in }
        sut.load(){_ in }
        XCTAssertEqual(client.requestedURLs,[url,url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSut()
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load {capturedErrors.append($0)}
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSut()
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load {capturedErrors.append($0)}
        client.complete(withStatus: 200)
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    //MARK - Helpers
    private func makeSut(url : URL = URL(string: "https://www.google.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url:URL, completions:(Error?, HTTPURLResponse?) -> Void)]()
        var requestedURLs: [URL] {
            return messages.map({$0.url})
        }
        
        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            messages.append( (url,completion))
        }
                
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completions(error, nil)
        }
        
        func complete(withStatus code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)
            messages[index].completions(nil, response)
        }
    }
}
