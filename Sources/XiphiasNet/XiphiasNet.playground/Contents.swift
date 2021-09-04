import XiphiasNet
import Foundation

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

public struct Networker {
    private init() { }

    public static func request<T: Codable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let payload = payload, !payload.isEmpty {
            let jsonData = try? JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
        }

        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            Self.handleDataTask(data: data, response: response, error: error, completion: completion)
        }
        if let config = config {
            task.priority = config.priority
        }
        task.resume()
    }

    public static func request<T: Codable>(
        from url: URL,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        ofType type: T,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        request(from: url, method: method, payload: payload, config: config, completion: completion)
    }

    public static func request<T: Codable>(
        from urlString: String,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL(url: urlString)))
            return
        }
        request(from: url, method: method, payload: payload, config: config, completion: completion)
    }

    public static func request<T: Codable>(
        from urlString: String,
        method: HTTPMethod = .get,
        payload: [String: Any]? = nil,
        ofType type: T,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        request(from: urlString, method: method, payload: payload, config: config, completion: completion)
    }

    private static func handleDataTask<T: Codable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        if let error = error {
            completion(.failure(.generalError(error: error)))
            return
        }

        guard let data = data, let response = response  else {
            completion(.failure(.notAValidJSON))
            return
        }

        let transformedResponseResult: Result<T, XiphiasNet.Errors> = self.transformResponseOutput(response, data)
        switch transformedResponseResult {
        case .failure(let failure): completion(.failure(failure))
        case .success(let success): completion(.success(success))
        }
    }

    private static func transformResponseOutput<T: Codable>(_ response: URLResponse, _ data: Data) -> Result<T, XiphiasNet.Errors> {
        guard let jsonString = String(data: data, encoding: .utf8) else {
            return .failure(.notAValidJSON)
        }

        if let response = response as? HTTPURLResponse, response.statusCode >= 400 {
            return .failure(.responseError(message: jsonString, code: response.statusCode))
        }

        let jsonResponse: T
        do {
            jsonResponse = try JSONDecoder().decode(T.self, from: data)
        } catch {
            return .failure(.parsingError(error: error))
        }
        return .success(jsonResponse)
    }
}

let config = XRequestConfig(priority: URLSessionTask.defaultPriority)

struct RootResponse: Codable {
    let hello: String
}

Networker.request(from: "http://localhost:8081", method: .get, config: config) { (result: Result<RootResponse, XiphiasNet.Errors>) in
    print("Networker", result)
}

struct PostResponse: Codable {
    let title: String
}

Networker.request(from: "http://localhost:8081/post", method: .post, payload: ["title": "ABC"], config: config) { (result: Result<PostResponse, XiphiasNet.Errors>) in
    print("Networker", result)
}
