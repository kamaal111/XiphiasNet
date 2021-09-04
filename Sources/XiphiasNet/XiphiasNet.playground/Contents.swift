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

public struct Response<T: Decodable> {
    public let data: T
    public let status: Int?

    public init(data: T, status: Int?) {
        self.data = data
        self.status = status
    }
}

public struct Networker {
    private init() { }

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
            Self.handleDataTask(data: data, response: response, error: error, kowalskiAnalysis: config?.kowalskiAnalysis ?? false, completion: completion)
        }
        if let config = config {
            task.priority = config.priority
        }
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

        let transformedResponseResult: Result<Response<T>, XiphiasNet.Errors> = self.transformResponseOutput(response, data, kowalskiAnalysis: kowalskiAnalysis)
        switch transformedResponseResult {
        case .failure(let failure): completion(.failure(failure))
        case .success(let success): completion(.success(success))
        }
    }

    private static func transformResponseOutput<T: Decodable>(_ response: URLResponse, _ data: Data, kowalskiAnalysis: Bool = false) -> Result<Response<T>, XiphiasNet.Errors> {
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

let config = XRequestConfig(priority: URLSessionTask.defaultPriority, kowalskiAnalysis: false)
let url = URL(string: "http://localhost:8081")!

struct RootResponse: Decodable {
    let hello: String
}

Networker.request(from: url, method: .get, config: config, responseType: RootResponse.self) { result in
    print(result)
}

struct PostResponse: Decodable {
    let title: String
}

Networker.request(from: url.appendingPathComponent("post"), method: .post, payload: ["title": "ABC"], config: config, responseType: PostResponse.self) { result in
    print(result)
}

struct HeadResponse: Decodable {
    let Superheader: [String]
}

Networker.request(from: url.appendingPathComponent("headers"), method: .post, headers: ["SuperHeader": "Yes"], config: config, responseType: HeadResponse.self) { result in
    print(result)
}
