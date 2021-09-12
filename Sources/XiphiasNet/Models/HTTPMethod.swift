//
//  File.swift
//  
//
//  Created by Kamaal M Farah on 04/09/2021.
//

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
