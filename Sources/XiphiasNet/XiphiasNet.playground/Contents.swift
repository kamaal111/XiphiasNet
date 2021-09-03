import XiphiasNet
import Foundation

let networker = XiphiasNet(kowalskiAnalysis: true)

struct RootResponse: Codable {
    let hello: String
}

let urlRequest = URLRequest(url: URL(string: "http://localhost:8081")!)
let config = XRequestConfig(priority: 2)
networker.request(from: urlRequest, config: config) { (result: Result<RootResponse?, XiphiasNet.Errors>) in
    print(result)
}

struct Networker {
    private init() { }

    static func get<T: Codable>(from url: URL, config: XRequestConfig? = nil, completion: @escaping (Result<T, XiphiasNet.Errors>) -> Void) {
        let request = URLRequest(url: url)
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
