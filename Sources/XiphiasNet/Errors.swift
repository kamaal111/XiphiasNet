//
//  Errors.swift
//  
//
//  Created by Kamaal M Farah on 04/09/2021.
//

import Foundation

public extension XiphiasNet {
    enum Errors: Error, Equatable {
        public static func == (lhs: XiphiasNet.Errors, rhs: XiphiasNet.Errors) -> Bool {
            lhs.identifier == rhs.identifier
        }

        case generalError(error: Error)
        case responseError(message: String, code: Int)
        case notAValidJSON
        case parsingError(error: Error)
        case invalidURL(url: String)

        private var identifier: String {
            switch self {
            case .generalError(error: let error): return "general_error_\(error.localizedDescription)"
            case .responseError(message: let message, code: let code): return "response_error_\(message)_\(code)"
            case .notAValidJSON: return "not_a_valid_json"
            case .parsingError(error: let error): return "parsing_error_\(error.localizedDescription)"
            case .invalidURL(url: let url): return "invalid_url_\(url)"
            }
        }
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
