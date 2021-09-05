//
//  XRequestConfig.swift
//  
//
//  Created by Kamaal M Farah on 04/09/2021.
//

import Foundation

public struct XRequestConfig {
    /// The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
    public let priority: Float
    public let kowalskiAnalysis: Bool

    public init(priority: Float = URLSessionTask.defaultPriority, kowalskiAnalysis: Bool = false) {
        if priority <= .zero {
            self.priority = URLSessionTask.lowPriority
        } else if priority > 1 {
            self.priority = URLSessionTask.highPriority
        } else {
            self.priority = priority
        }
        self.kowalskiAnalysis = kowalskiAnalysis
    }
}
