//
//  AppGroup.swift
//  ExpenseSnap
//
//  Created by Bora Mert on 25.05.2025.
//

import Foundation

public enum AppGroup: String {
    case pockt = "group.pockt.boramerts"
    
    public var containerURL: URL {
        switch self {
        case .pockt:
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.rawValue)!
        }
    }
}
