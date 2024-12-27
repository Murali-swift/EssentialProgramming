//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 27/12/24.
//
import Foundation

public protocol HTTPClient {
    func get(from url:URL, completion: @escaping (HTTPClientResult) -> Void)
}

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}
