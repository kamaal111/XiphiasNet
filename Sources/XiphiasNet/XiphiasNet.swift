//
//  XiphiasNet.swift
//  XiphiasNet
//
//  Created by Kamaal Farah on 28/11/2020.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

public protocol XiphiasNetable {
    func loadImage(from imageUrl: URL, completion: @escaping (Result<Data, XiphiasNet.Errors>) -> Void)
    func requestData(from url: URL, completion: @escaping (Result<Data, XiphiasNet.Errors>) -> Void)
    func request<T: Codable>(from request: URLRequest, config: XRequestConfig?, completion: @escaping (Result<T?, XiphiasNet.Errors>) -> Void)
    func request<T: Codable>(from request: URLRequest, completion: @escaping (Result<T?, XiphiasNet.Errors>) -> Void)
    func request<T: Codable>(from request: URL, config: XRequestConfig?, completion: @escaping (Result<T?, XiphiasNet.Errors>) -> Void)
    func request<T: Codable>(from request: URL, completion: @escaping (Result<T?, XiphiasNet.Errors>) -> Void)
    #if canImport(Combine)
    @available(macOS 10.15.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func requestPublisher<T: Codable>(from urlRequest: URLRequest) -> AnyPublisher<T?, Error>
    @available(macOS 10.15.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func requestPublisher<T: Codable>(from url: URL) -> AnyPublisher<T?, Error>
    #endif
}

public struct XRequestConfig {
    /// The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
    public let priority: Float
    public let kowalskiAnalysis: Bool

    public init(priority: Float = URLSessionTask.defaultPriority, kowalskiAnalysis: Bool = false) {
        if priority <= .zero {
            self.priority = URLSessionTask.lowPriority
        } else if priority > 1 {
            self.priority = URLSessionTask.highPriority
        } else {
            self.priority = priority
        }
        self.kowalskiAnalysis = kowalskiAnalysis
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

    #if canImport(Combine)
    @available(macOS 10.15.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func requestPublisher<T: Codable>(from urlRequest: URLRequest) -> AnyPublisher<T?, Error> {
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap({ (output: URLSession.DataTaskPublisher.Output) -> T? in
                let transformedResponseResult: Result<T?, Errors> = transformResponseOutput(output.response, output.data)
                switch transformedResponseResult {
                case .failure(let failure): throw failure
                case .success(let success): return success
                }
            })
            .eraseToAnyPublisher()
    }

    @available(macOS 10.15.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func requestPublisher<T: Codable>(from url: URL) -> AnyPublisher<T?, Error> {
        requestPublisher(from: url.request)
    }
    #endif

    func request<T: Codable>(from url: URL, config: XRequestConfig?, completion: @escaping (Result<T?, Errors>) -> Void) {
        request(from: url.request, config: config, completion: completion)
    }

    func request<T: Codable>(from urlRequest: URLRequest, config: XRequestConfig?, completion: @escaping (Result<T?, Errors>) -> Void) {
        let task = URLSession.shared.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            self._request(data: data, response: response, error: error, completion: completion)
        }
        task.setConfig(with: config)
        task.resume()
    }
}

private extension URLSessionDataTask {
    func setConfig(with config: XRequestConfig?) {
        if let config = config {
            self.priority = config.priority
        }
    }
}

private extension URL {
    var request: URLRequest {
        URLRequest(url: self)
    }
}

private extension XiphiasNet {
    func _request<T: Codable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T?, Errors>) -> Void) {
        if let error = error {
            completion(.failure(.generalError(error: error)))
            return
        }
        guard let data = data, let response = response  else {
            completion(.failure(.notAValidJSON))
            return
        }
        let transformedResponseResult: Result<T?, Errors> = transformResponseOutput(response, data)
        switch transformedResponseResult {
        case .failure(let failure): completion(.failure(failure))
        case .success(let success): completion(.success(success))
        }
    }

    func transformResponseOutput<T: Codable>(_ response: URLResponse, _ data: Data) -> Result<T?, Errors> {
        guard let jsonString = String(data: data, encoding: .utf8) else {
            return .failure(.notAValidJSON)
        }
        analys("XiphiasNet -> JSON RESPONSE: \(jsonString)")
        if let response = response as? HTTPURLResponse {
            if response.statusCode >= 400 {
                return .failure(.responseError(message: jsonString, code: response.statusCode))
            } else if response.statusCode == 204 {
                 return .success(nil)
            }
        }
        let jsonResponse: T
        do {
            jsonResponse = try jsonDecoder.decode(T.self, from: data)
        } catch {
            return .failure(.parsingError(error: error))
        }
        return .success(jsonResponse)
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
        case notAValidJSON
        case parsingError(error: Error)
        case invalidURL(url: String)
    }
}

extension XiphiasNet.Errors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .responseError(message: let message, code: let code):
            return "Response error, Status code: \(code); Message: \(message)"
        case .notAValidJSON:
            return "Not a valid json"
        case .generalError(error: let error):
            return "General error; \(error.localizedDescription); \(error)"
        case .parsingError(error: let error):
            return "Parsing error; \(error.localizedDescription); \(error)"
        case .invalidURL(url: let url):
            return "Provided a invalid URL of \(url)"
        }
    }
}
