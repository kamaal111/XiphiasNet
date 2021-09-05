//
//  Response.swift
//  
//
//  Created by Kamaal M Farah on 04/09/2021.
//

import Foundation

public struct Response<T: Decodable> {
    public let data: T
    public let status: Int?

    public init(data: T, status: Int?) {
        self.data = data
        self.status = status
    }
}
