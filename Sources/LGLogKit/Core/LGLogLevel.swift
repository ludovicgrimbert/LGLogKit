//
//  LGLogLevel.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

/// Severity of an entry. `.error` (raw value 0) is the most important and is always
/// allowed; the higher the raw value, the chattier the level. An entry is emitted when
/// its level is `<=` the level allowed for its emitter.
public enum LGLogLevel: Int, Comparable, CaseIterable, Sendable {

    /// Fatal to the operation but not to the app: a failed API call, missing data, an
    /// unexpected nil. Usually needs the user to do something.
    case error = 0

    /// Something odd happened but the app recovered by itself (a retry, a fallback…).
    case warning

    /// Generally useful information: service start/stop, configuration, milestones.
    /// Always worth having, rarely worth reading.
    case info

    /// Diagnostically helpful to a developer chasing an issue.
    case debug

    /// Tracing: which branch ran, with which values. Extensive by design.
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
        case .error:   "error"
        case .warning: "warning"
        case .info:    "info"
        case .debug:   "debug"
        case .verbose: "verbose"
        }
    }

    public static func < (lhs: LGLogLevel, rhs: LGLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
