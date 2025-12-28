//
//  LGLogLevel.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

/// The `.error`/0  has the most priotity and should always be
/// authorized to log. The upper you go, the less priority it has.
public enum LGLogLevel: Int, Equatable, CaseIterable, Sendable {
    
    /// Any error which is fatal to the operation,
    /// but not the service or application (can’t open a required file,
    /// missing data, unexpected nil value, etc.)
    /// These errors will force user intervention.
    /// These are usually reserved for failed API calls, missing services, etc.
    case error = 0
    
    /// Anything that can potentially cause application oddities
    /// but an automatic recovery is possible (such as retrying an operation,
    /// missing data, etc.)
    case warning
    
    /// Generally useful information (service start/stop,
    /// configuration assumptions, etc).
    /// Info to always have available but usually don’t care about
    /// under normal circumstances.
    case info
    
    /// Information that is diagnostically helpful to developers
    /// to diagnose an issue.
    case debug
    
    /// Use to trace the code,
    /// trying to find one part of a function specifically,
    /// sort of debuggin with extensive information.
    case verbose
    
    public var symbol: String {
        switch self {
        case .error:   "🔴"
        case .warning: "🟠"
        case .info:    "🟡"
        case .debug:   "🔵"
        case .verbose: "⚪️"
        }
    }
    
    public var name: String {
        switch self {
        case .error: "error"
        case .warning: "warning"
        case .info: "info"
        case .debug: "debug"
        case .verbose: "verbose"
        }
    }
}

// So we can easily filter Log Levels
extension LGLogLevel: Comparable {
    public static func < (lhs: LGLogLevel, rhs: LGLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
