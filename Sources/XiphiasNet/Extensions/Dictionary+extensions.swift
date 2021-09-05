//
//  Dictionary+extensions.swift
//  
//
//  Created by Kamaal M Farah on 05/09/2021.
//

import Foundation

extension Dictionary {
    var asData: Data? {
        guard !self.isEmpty else { return nil }
        return try? JSONSerialization.data(withJSONObject: self)
    }
}
