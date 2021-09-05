//
//  URLSessionDataTask+extensions.swift
//  
//
//  Created by Kamaal M Farah on 04/09/2021.
//

import Foundation

extension URLSessionDataTask {
    func setConfig(with config: XRequestConfig?) {
        if let config = config {
            self.priority = config.priority
        }
    }
}
