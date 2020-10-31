//
//  XiphiasNet.swift
//
//
//  Created by Kamaal Farah on 10/09/2020.
//

import Foundation

public protocol XiphiasNetable {
    func loadImage(from imageUrl: URL, completion: @escaping (Result<Data, Error>) -> Void)
    func requestData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void)
    func request<T: Codable>(from request: URLRequest, completion: @escaping (Result<T, Error>) -> Void)
    func request<T: Codable>(from request: URL, completion: @escaping (Result<T, Error>) -> Void)
}

public struct XiphiasNet: XiphiasNetable {
    public var jsonDecoder = JSONDecoder()

    private let kowalskiAnalysis: Bool

    public init(kowalskiAnalysis: Bool = false) {
        self.kowalskiAnalysis = kowalskiAnalysis
    }

    internal enum NetworkerErrors: Error {
        case responseError(message: String, code: Int)
        case dataError(message: String, code: Int)
    }
}

public extension XiphiasNet {
    func loadImage(from imageUrl: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        requestData(from: imageUrl) { (result: Result<Data, Error>) in
            completion(result)
        }
    }

    func requestData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        _requestData(from: url) { (result: Result<Data, Error>) in
            completion(result)
        }
    }

    func request<T: Codable>(from urlRequest: URLRequest, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            self._request(data: data, response: response, error: error) { (result: Result<T, Error>) in
                completion(result)
            }
        }
        .resume()
    }

    func request<T: Codable>(from url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            self._request(data: data, response: response, error: error) { (result: Result<T, Error>) in
                completion(result)
            }
        }
        .resume()
    }
}

private extension XiphiasNet {
    func _request<T: Codable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let dataResponse = data else {
            let error = NetworkerErrors.dataError(message: "data error", code: 400)
            completion(.failure(error))
            return
        }
        guard let jsonString = String(data: dataResponse, encoding: .utf8) else {
            completion(.failure(NSError(domain: "could not get json string", code: 400, userInfo: nil)))
            return
        }
        self.analys("XiphiasNet -> JSON RESPONSE: \(jsonString)")
        if let response = response as? HTTPURLResponse, response.statusCode >= 400 {
            let error = NetworkerErrors.responseError(message: "response code error",
                                                      code: response.statusCode)
            completion(.failure(error))
            return
        }
        do {
            let jsonResponse = try self.jsonDecoder.decode(T.self, from: dataResponse)
            completion(.success(jsonResponse))
        } catch let parsingError {
            completion(.failure(parsingError))
        }
    }

    func _requestData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let dataResponse = data else {
                let error = NetworkerErrors.dataError(message: "data error", code: 400)
                completion(.failure(error))
                return
            }
            if let response = response as? HTTPURLResponse, response.statusCode >= 400 {
                let error = NetworkerErrors.responseError(message: "response code error",
                                                          code: response.statusCode)
                completion(.failure(error))
                return
            }
            completion(.success(dataResponse))
        }
        .resume()
    }

    func analys(_ message: String) {
        if kowalskiAnalysis {
            print(message)
        }
    }
}
