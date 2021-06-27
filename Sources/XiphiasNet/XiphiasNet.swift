//
//  XiphiasNet.swift
//  XiphiasNet
//
//  Created by Kamaal Farah on 28/11/2020.
//

import Foundation

public protocol XiphiasNetable {
    func loadImage(from imageUrl: URL, completion: @escaping (Result<Data, XiphiasNet.Errors>) -> Void)
    func requestData(from url: URL, completion: @escaping (Result<Data, XiphiasNet.Errors>) -> Void)
    func request<T: Codable>(from request: URLRequest, config: XRequestConfig?, completion: @escaping (Result<T?, XiphiasNet.Errors>) -> Void)
    func request<T: Codable>(from request: URLRequest, completion: @escaping (Result<T?, XiphiasNet.Errors>) -> Void)
    func request<T: Codable>(from request: URL, config: XRequestConfig?, completion: @escaping (Result<T?, XiphiasNet.Errors>) -> Void)
    func request<T: Codable>(from request: URL, completion: @escaping (Result<T?, XiphiasNet.Errors>) -> Void)
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
    func loadImage(from imageUrl: URL, completion: @escaping (Result<Data, Errors>) -> Void) {
        _requestData(from: imageUrl, completion: completion)
    }

    func requestData(from url: URL, completion: @escaping (Result<Data, Errors>) -> Void) {
        _requestData(from: url, completion: completion)
    }

    func request<T: Codable>(from urlRequest: URLRequest, completion: @escaping (Result<T?, Errors>) -> Void) {
        request(from: urlRequest, config: nil, completion: completion)
    }

    func request<T: Codable>(from url: URL, completion: @escaping (Result<T?, Errors>) -> Void) {
        request(from: url, config: nil, completion: completion)
    }

    func request<T: Codable>(from url: URL, config: XRequestConfig?, completion: @escaping (Result<T?, Errors>) -> Void) {
        let urlRequest = URLRequest(url: url)
        request(from: urlRequest, config: config, completion: completion)
    }

    func request<T: Codable>(from urlRequest: URLRequest, config: XRequestConfig?, completion: @escaping (Result<T?, Errors>) -> Void) {
        let task = URLSession.shared.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
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
    func _request<T: Codable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T?, Errors>) -> Void) {
        if let error = error {
            completion(.failure(.generalError(error: error)))
            return
        }
        guard let dataResponse = data else {
            completion(.failure(.dataError))
            return
        }
        guard let jsonString = String(data: dataResponse, encoding: .utf8) else {
            completion(.failure(.notAValidJSON))
            return
        }
        analys("XiphiasNet -> JSON RESPONSE: \(jsonString)")
        if let response = response as? HTTPURLResponse {
            if response.statusCode >= 400 {
                completion(.failure(.responseError(message: jsonString, code: response.statusCode)))
                return
            } else if response.statusCode == 204 {
                completion(.success(nil))
                return
            }
        }
        do {
            let jsonResponse = try jsonDecoder.decode(T.self, from: dataResponse)
            completion(.success(jsonResponse))
        } catch {
            completion(.failure(.parsingError(error: error)))
        }
    }

    func _requestData(from url: URL, completion: @escaping (Result<Data, Errors>) -> Void) {
        do {
            let data = try Data(contentsOf: url)
            completion(.success(data))
        } catch {
            completion(.failure(.generalError(error: error)))
        }
    }

    func analys(_ message: String) {
        if kowalskiAnalysis {
            print(message)
        }
    }
}

public extension XiphiasNet {
    enum Errors: Error {
        case generalError(error: Error)
        case responseError(message: String, code: Int)
        case dataError
        case notAValidJSON
        case parsingError(error: Error)
    }
}

extension XiphiasNet.Errors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .responseError(message: let message, code: let code):
            return "Response error, Status code: \(code); Message: \(message)"
        case .dataError:
            return "Data error"
        case .notAValidJSON:
            return "Not a valid json"
        case .generalError(error: let error):
            return "General error; \(error.localizedDescription); \(error)"
        case .parsingError(error: let error):
            return "Parsing error; \(error.localizedDescription); \(error)"
        }
    }
}
