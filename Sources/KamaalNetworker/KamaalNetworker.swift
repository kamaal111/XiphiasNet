//
//  Networker.swift
//
//
//  Created by Kamaal Farah on 10/09/2020.
//

import Foundation

public protocol KamaalNetworkable {
    func loadImage(from imageUrl: String, completion: @escaping (Result<Data, Error>) -> Void)
    func request<T: Codable>(_ type: T.Type, from request: URLRequest, completion: @escaping (Result<T, Error>) -> Void)
}

public struct KamaalNetworker: KamaalNetworkable {
    public var jsonDecoder = JSONDecoder()

    private let kowalskiAnalysis: Bool

    public init(kowalskiAnalysis: Bool = false) {
        self.kowalskiAnalysis = kowalskiAnalysis
    }
}

public extension KamaalNetworker {
    func loadImage(from imageUrl: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: imageUrl) else {
            completion(.failure(NSError(domain: "url error", code: 400, userInfo: nil)))
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard (response as? HTTPURLResponse) != nil else {
                completion(.failure(NSError(domain: "response code error", code: 400, userInfo: nil)))
                return
            }
            guard let dataResponse = data else {
                completion(.failure(NSError(domain: "data error", code: 400, userInfo: nil)))
                return
            }
            completion(.success(dataResponse))
        }
        .resume()
    }

    func request<T: Codable>(_ type: T.Type, from urlRequest: URLRequest, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let dataResponse = data else {
                completion(.failure(NSError(domain: "data error", code: 400, userInfo: nil)))
                return
            }
            guard let jsonString = String(data: dataResponse, encoding: .utf8) else {
                completion(.failure(NSError(domain: "could not get json string", code: 400, userInfo: nil)))
                return
            }
            self.analys("KamaalNetworker -> JSON RESPONSE: \(jsonString)")
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "response error", code: 400, userInfo: nil)))
                return
            }
            if response.statusCode != 200 {
                self.analys("KamaalNetworker -> STATUS CODE: \(response.statusCode)")
                completion(.failure(NSError(domain: "response error", code: response.statusCode, userInfo: nil)))
                return
            }
            do {
                
                let jsonResponse = try self.jsonDecoder.decode(type, from: dataResponse)
                completion(.success(jsonResponse))
            } catch let parsingError {
                completion(.failure(parsingError))
            }
        }
        .resume()
    }
}

private extension KamaalNetworker {
    func analys(_ message: String) {
        if kowalskiAnalysis {
            print(message)
        }
    }
}
