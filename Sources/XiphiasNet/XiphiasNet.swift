//
//  XiphiasNet.swift
//  XiphiasNet
//
//  Created by Kamaal Farah on 28/11/2020.
//

import Foundation

public protocol XiphiasNetable {
    func loadImage(from imageUrl: URL, completion: @escaping (Result<Data, Error>) -> Void)
    func requestData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void)
    func request<T: Codable>(from request: URLRequest, config: XRequestConfig?, completion: @escaping (Result<T, Error>) -> Void)
    func request<T: Codable>(from request: URLRequest, completion: @escaping (Result<T, Error>) -> Void)
    func request<T: Codable>(from request: URL, config: XRequestConfig?, completion: @escaping (Result<T, Error>) -> Void)
    func request<T: Codable>(from request: URL, completion: @escaping (Result<T, Error>) -> Void)
}

public struct XRequestConfig {
    public let priority: Float

    public init(priority: Float = URLSessionTask.defaultPriority) {
        if priority <= .zero {
            self.priority = URLSessionTask.lowPriority
        } else if priority > 1 {
            self.priority = URLSessionTask.highPriority
        } else {
            self.priority = priority
        }
    }
}

public struct XiphiasNet: XiphiasNetable {
    public var jsonDecoder = JSONDecoder()

    private let kowalskiAnalysis: Bool

    public init(kowalskiAnalysis: Bool = false) {
        self.kowalskiAnalysis = kowalskiAnalysis
    }
}

public extension XiphiasNet {
    func loadImage(from imageUrl: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        _requestData(from: imageUrl, completion: completion)
    }

    func requestData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        _requestData(from: url, completion: completion)
    }

    func request<T: Codable>(from urlRequest: URLRequest, completion: @escaping (Result<T, Error>) -> Void) {
        request(from: urlRequest, config: nil, completion: completion)
    }

    func request<T: Codable>(from urlRequest: URLRequest, config: XRequestConfig?, completion: @escaping (Result<T, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            self._request(data: data, response: response, error: error, completion: completion)
        }
        task.setConfig(with: config)
        task.resume()
    }

    func request<T: Codable>(from url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        request(from: url, config: nil, completion: completion)
    }

    func request<T: Codable>(from url: URL, config: XRequestConfig?, completion: @escaping (Result<T, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            self._request(data: data, response: response, error: error, completion: completion)
        }
        task.setConfig(with: config)
        task.resume()
    }
}

fileprivate extension URLSessionDataTask {
    func setConfig(with config: XRequestConfig?) {
        if let config = config {
            self.priority = config.priority
        }
    }
}

private extension XiphiasNet {
    func _request<T: Codable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let dataResponse = data else {
            let error = NetworkerErrors.dataError
            completion(.failure(error))
            return
        }
        guard let jsonString = String(data: dataResponse, encoding: .utf8) else {
            completion(.failure(NetworkerErrors.notAValidJSON))
            return
        }
        analys("XiphiasNet -> JSON RESPONSE: \(jsonString)")
        if let response = response as? HTTPURLResponse {
            if response.statusCode >= 400 {
                let error = NetworkerErrors.responseError(message: jsonString,
                                                          code: response.statusCode)
                completion(.failure(error))
                return
            } else if response.statusCode == 204 {
                /// - ToDo: Make response optional and return nil in completion as success
            }
        }
        do {
            let jsonResponse = try jsonDecoder.decode(T.self, from: dataResponse)
            completion(.success(jsonResponse))
        } catch let parsingError {
            completion(.failure(parsingError))
        }
    }

    func _requestData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            let data = try Data(contentsOf: url)
            completion(.success(data))
        } catch {
            completion(.failure(error))
        }
    }

    func analys(_ message: String) {
        if kowalskiAnalysis {
            print(message)
        }
    }
}

public extension XiphiasNet {
    enum NetworkerErrors: Error {
        case responseError(message: String, code: Int)
        case dataError
        case notAValidJSON
    }
}

extension XiphiasNet.NetworkerErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .responseError(message: let message, code: let code):
            return "Response error, Status code: \(code); Message: \(message)"
        case .dataError:
            return "Data error"
        case .notAValidJSON:
            return "Not a valid json"
        }
    }
}
