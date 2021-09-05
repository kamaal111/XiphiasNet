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

    public init(priority: Float = XRequestConfig.defaultPriority, kowalskiAnalysis: Bool = false) {
        if priority <= .zero {
            self.priority = XRequestConfig.lowPriority
        } else if priority > 1 {
            self.priority = XRequestConfig.highPriority
        } else {
            self.priority = priority
        }
        self.kowalskiAnalysis = kowalskiAnalysis
    }

    public static let lowPriority: Float = 0
    public static let defaultPriority: Float = 0.5
    public static let highPriority: Float = 1
}
