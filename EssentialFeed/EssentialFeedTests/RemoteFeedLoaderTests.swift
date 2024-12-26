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
        expect(sut, toCompleteWithError: .connectivity) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSut()
        let samples = [199, 201, 300, 400, 500].enumerated()
        samples.forEach { index,code in
            expect(sut, toCompleteWithError: .invalidData) {
                client.complete(withStatus: code, at: index)
            }
        }
    }
    
    func test_load_deliversError200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWithError: .invalidData) {
            let invalidJSON = Data("Invalid JSON".utf8)
            client.complete(withStatus:200, data:invalidJSON)
        }
       
    }
    
    //MARK - Helpers
    private func makeSut(url : URL = URL(string: "https://www.google.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url:url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error:RemoteFeedLoader.Error, when action:() -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load {capturedErrors.append($0)}
        action()
        XCTAssertEqual(capturedErrors, [error], file:file, line: line)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url:URL, completions:(HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            return messages.map({$0.url})
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append( (url,completion))
        }
                
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completions(.failure(error))
        }
        
        func complete(withStatus code: Int, data:Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completions(.success(data,response))
        }
    }
}
