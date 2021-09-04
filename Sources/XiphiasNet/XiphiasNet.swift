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

public class XiphiasNet {
    private init() { }

    public static func loadImage(from imageURL: URL) -> Result<Data, XiphiasNet.Errors> {
        requestData(from: imageURL)
    }

    public static func loadImage(from imageURLString: String) -> Result<Data, XiphiasNet.Errors> {
        guard let imageURL = URL(string: imageURLString) else { return .failure(.invalidURL(url: imageURLString)) }
        return requestData(from: imageURL)
    }

    public static func requestData(from urlString: String) -> Result<Data, XiphiasNet.Errors> {
        guard let url = URL(string: urlString) else { return .failure(.invalidURL(url: urlString)) }
        return requestData(from: url)
    }

    public static func requestData(from url: URL) -> Result<Data, XiphiasNet.Errors> {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return .failure(.generalError(error: error))
        }
        return .success(data)
    }

    public static func request<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil,
        responseType: T.Type,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        request(from: url, method: method, payload: payload, headers: headers, config: config, completion: completion)
    }

    public static func request<T: Decodable>(
        from urlString: String,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil,
        responseType: T.Type,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        request(from: urlString, method: method, payload: payload, headers: headers, config: config, completion: completion)
    }

    #if canImport(Combine)
    @available(macOS 10.15.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func requestPublisher<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type,
        config: XRequestConfig? = nil) -> AnyPublisher<Response<T>, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers

        if let payload = payload, !payload.isEmpty {
            let jsonData = try? JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap({ (output: URLSession.DataTaskPublisher.Output) -> Response<T> in
                let transformedResponseResult: Result<Response<T>, Errors> = transformResponseOutput(
                    response: output.response,
                    data: output.data,
                    kowalskiAnalysis: config?.kowalskiAnalysis ?? false)
                switch transformedResponseResult {
                case .failure(let failure): throw failure
                case .success(let success): return success
                }
            })
            .eraseToAnyPublisher()
    }
    #endif

    private static func request<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers

        if let payload = payload, !payload.isEmpty {
            let jsonData = try? JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
        }

        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            handleDataTask(data: data, response: response, error: error, kowalskiAnalysis: config?.kowalskiAnalysis ?? false, completion: completion)
        }

        task.setConfig(with: config)

        task.resume()
    }

    private static func request<T: Decodable>(
        from urlString: String,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL(url: urlString)))
            return
        }
        request(from: url, method: method, payload: payload, headers: headers, config: config, completion: completion)
    }

    private static func handleDataTask<T: Decodable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        kowalskiAnalysis: Bool = false,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        if let error = error {
            completion(.failure(.generalError(error: error)))
            return
        }

        guard let data = data, let response = response  else {
            completion(.failure(.notAValidJSON))
            return
        }

        let transformedResponseResult: Result<Response<T>, XiphiasNet.Errors> = transformResponseOutput(
            response: response,
            data: data,
            kowalskiAnalysis: kowalskiAnalysis)
        switch transformedResponseResult {
        case .failure(let failure): completion(.failure(failure))
        case .success(let success): completion(.success(success))
        }
    }

    private static func transformResponseOutput<T: Decodable>(response: URLResponse, data: Data, kowalskiAnalysis: Bool = false) -> Result<Response<T>, XiphiasNet.Errors> {
        guard let jsonString = String(data: data, encoding: .utf8) else {
            return .failure(.notAValidJSON)
        }

        if kowalskiAnalysis {
            print("JSON STRING RESPONSE", jsonString)
        }

        var statusCode: Int?
        if let response = response as? HTTPURLResponse {
            statusCode = response.statusCode
            guard response.statusCode < 400 else { return .failure(.responseError(message: jsonString, code: response.statusCode)) }
        }
        if let response = response as? HTTPURLResponse, response.statusCode >= 400 {
            return .failure(.responseError(message: jsonString, code: response.statusCode))
        }

        let decodedResponse: T
        do {
            decodedResponse = try JSONDecoder().decode(T.self, from: data)
        } catch {
            return .failure(.parsingError(error: error))
        }
        let response = Response(data: decodedResponse, status: statusCode)
        return .success(response)
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

public struct Response<T: Decodable> {
    public let data: T
    public let status: Int?

    public init(data: T, status: Int?) {
        self.data = data
        self.status = status
    }
}

public struct HTTPMethod: RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public typealias RawValue = String

    public static let get = HTTPMethod(rawValue: "GET")
    public static let head = HTTPMethod(rawValue: "HEAD")
    public static let post = HTTPMethod(rawValue: "POST")
    public static let put = HTTPMethod(rawValue: "PUT")
    public static let delete = HTTPMethod(rawValue: "DELETE")
    public static let connect = HTTPMethod(rawValue: "CONNECT")
    public static let options = HTTPMethod(rawValue: "OPTIONS")
    public static let trace = HTTPMethod(rawValue: "TRACE")
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

private extension URLSessionDataTask {
    func setConfig(with config: XRequestConfig?) {
        if let config = config {
            self.priority = config.priority
        }
    }
}
