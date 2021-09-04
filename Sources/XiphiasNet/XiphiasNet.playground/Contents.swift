import XiphiasNet
import Foundation

struct RootResponse: Codable {
    let hello: String
}

let url = URL(string: "http://localhost:8081")!
let urlRequest = URLRequest(url: url)
let config = XRequestConfig(priority: 2)

struct HTTPMethod: RawRepresentable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    typealias RawValue = String

    static let get = HTTPMethod(rawValue: "GET")
    static let head = HTTPMethod(rawValue: "HEAD")
    static let post = HTTPMethod(rawValue: "POST")
    static let put = HTTPMethod(rawValue: "PUT")
    static let delete = HTTPMethod(rawValue: "DELETE")
    static let connect = HTTPMethod(rawValue: "CONNECT")
    static let options = HTTPMethod(rawValue: "OPTIONS")
    static let trace = HTTPMethod(rawValue: "TRACE")
}

struct Networker {
    private init() { }

    static func request<T: Codable>(
        from url: URL,
        method: HTTPMethod = .get,
        config: XRequestConfig? = nil,
        completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
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
        if let config = config {
            task.priority = config.priority
        }
        task.resume()
    }

    static func request<T: Codable>(from url: URL, method: HTTPMethod = .get, ofType type: T, config: XRequestConfig? = nil, completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        request(from: url, method: method, config: config, completion: completion)
    }

    static func request<T: Codable>(from urlString: String, method: HTTPMethod = .get, config: XRequestConfig? = nil, completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL(url: urlString)))
            return
        }
        request(from: url, method: method, config: config, completion: completion)
    }

    static func transformResponseOutput<T: Codable>(_ response: URLResponse, _ data: Data) -> Result<T, XiphiasNet.Errors> {
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

Networker.request(from: url, method: .get, config: config) { (result: Result<RootResponse, XiphiasNet.Errors>) in
    print("Networker", result)
}
