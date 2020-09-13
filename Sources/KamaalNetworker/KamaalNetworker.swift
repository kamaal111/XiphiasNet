//
//  Networker.swift
//
//
//  Created by Kamaal Farah on 10/09/2020.
//

import Foundation

public protocol KamaalNetworkable {
    func loadImage(from imageUrl: String, completion: @escaping (Result<Data, Error>) -> Void)
    func post<T: Codable>(_ type: T.Type, from request: URLRequest, completion: @escaping (Result<T, Error>) -> Void)
}

public class KamaalNetworker: KamaalNetworkable {
    public var jsonDecoder = JSONDecoder()

    private let kowalskiAnalysis: Bool

    public init(kowalskiAnalysis: Bool = false) {
        self.kowalskiAnalysis = kowalskiAnalysis
    }

    public func loadImage(from imageUrl: String, completion: @escaping (Result<Data, Error>) -> Void) {
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

    public func post<T: Codable>(_ type: T.Type, from request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let self = self else {
                completion(.failure(NSError(domain: "What the hell", code: 500, userInfo: nil)))
                return
            }
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
            self.analys(jsonString)
            do {
                let jsonResponse = try self.jsonDecoder.decode(type, from: dataResponse)
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "response error", code: 400, userInfo: nil)))
                    return
                }
                if response.statusCode != 200 {
                    print(response.statusCode)
                    completion(.failure(NSError(domain: "response error", code: response.statusCode, userInfo: nil)))
                    return
                }
                completion(.success(jsonResponse))
            } catch let parsingError {
                completion(.failure(parsingError))
            }
        }
        .resume()
    }

    func analys(_ message: String) {
        if kowalskiAnalysis {
            print(message)
        }
    }
}
