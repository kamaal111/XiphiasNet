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
    let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func loadImage(from imageURL: URL) -> Result<Data, XiphiasNet.Errors> {
        requestData(from: imageURL)
    }

    public func loadImage(from imageURLString: String) -> Result<Data, XiphiasNet.Errors> {
        guard let imageURL = URL(string: imageURLString) else { return .failure(.invalidURL(url: imageURLString)) }
        return requestData(from: imageURL)
    }

    public func requestData(from urlString: String) -> Result<Data, XiphiasNet.Errors> {
        guard let url = URL(string: urlString) else { return .failure(.invalidURL(url: urlString)) }
        return requestData(from: url)
    }

    public func requestData(from url: URL) -> Result<Data, XiphiasNet.Errors> {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return .failure(.generalError(error: error))
        }
        return .success(data)
    }

    public func request<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: Data?,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        let request = setupURLRequest(url: url, method: method, payload: payload, headers: headers)

        let task = urlSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            self.handleDataTask(
                data: data,
                response: response,
                error: error,
                kowalskiAnalysis: config?.kowalskiAnalysis ?? false,
                completion: completion)
        }

        task.setConfig(with: config)

        task.resume()
    }

    @available(iOS 13.0.0, macOS 10.15.0, tvOS 13.0.0, watchOS 6.0.0, *)
    public func request<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: Data?,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil) async -> Result<Response<T>, XiphiasNet.Errors> {
            await withCheckedContinuation({ continuation in
                request(
                    from: url,
                    method: method,
                    payload: payload,
                    headers: headers,
                    config: config,
                    completion: continuation.resume(returning:))
            })
        }

    public func request<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        request(from: url, method: method, payload: payload?.asData, headers: headers, config: config, completion: completion)
    }

    @available(iOS 13.0.0, macOS 10.15.0, tvOS 13.0.0, watchOS 6.0.0, *)
    public func request<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil) async -> Result<Response<T>, XiphiasNet.Errors> {
            await withCheckedContinuation({ continuation in
                request(
                    from: url,
                    method: method,
                    payload: payload,
                    headers: headers,
                    config: config,
                    completion: continuation.resume(returning:))
            })
        }

    public func request<T: Decodable>(
        from urlString: String,
        method: HTTPMethod = .get,
        payload: Data?,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL(url: urlString)))
            return
        }
        request(from: url, method: method, payload: payload, headers: headers, config: config, completion: completion)
    }

    @available(iOS 13.0.0, macOS 10.15.0, tvOS 13.0.0, watchOS 6.0.0, *)
    public func request<T: Decodable>(
        from urlString: String,
        method: HTTPMethod = .get,
        payload: Data?,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil) async -> Result<Response<T>, XiphiasNet.Errors> {
            await withCheckedContinuation({ continuation in
                request(
                    from: urlString,
                    method: method,
                    payload: payload,
                    headers: headers,
                    config: config,
                    completion: continuation.resume(returning:))
            })
        }

    public func request<T: Decodable>(
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

    @available(iOS 13.0.0, macOS 10.15.0, tvOS 13.0.0, watchOS 6.0.0, *)
    public func request<T: Decodable>(
        from urlString: String,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil) async -> Result<Response<T>, XiphiasNet.Errors> {
            await withCheckedContinuation({ continuation in
                request(
                    from: urlString,
                    method: method,
                    payload: payload,
                    headers: headers,
                    config: config,
                    completion: continuation.resume(returning:))
            })
        }

    public func request<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil,
        responseType: T.Type,
        completion: @escaping (Result<Response<T>, XiphiasNet.Errors>) -> Void) {
        request(from: url, method: method, payload: payload, headers: headers, config: config, completion: completion)
    }

    public func request<T: Decodable>(
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
    public func requestPublisher<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        config: XRequestConfig? = nil) -> AnyPublisher<Response<T>, Error> {
        let request = setupURLRequest(url: url, method: method, payload: payload?.asData, headers: headers)

        return urlSession.dataTaskPublisher(for: request)
            .tryMap({ (output: URLSession.DataTaskPublisher.Output) -> Response<T> in
                let transformedResponseResult: Result<Response<T>, XiphiasNet.Errors> = self.transformResponseOutput(
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

    @available(macOS 10.15.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func requestPublisher<T: Decodable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type,
        config: XRequestConfig? = nil) -> AnyPublisher<Response<T>, Error> {
        requestPublisher(from: url, method: method, payload: payload, headers: headers, config: config)
    }
    #endif
}

extension XiphiasNet {
    private func setupURLRequest(url: URL, method: HTTPMethod, payload: Data?, headers: [String: String]?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = payload
        return request
    }

    private func handleDataTask<T: Decodable>(
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

    private func transformResponseOutput<T: Decodable>(
        response: URLResponse,
        data: Data,
        kowalskiAnalysis: Bool = false) -> Result<Response<T>, XiphiasNet.Errors> {
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
