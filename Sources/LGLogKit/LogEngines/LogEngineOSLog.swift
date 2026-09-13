//
//  LogEngineOSLog.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

import Foundation
import OSLog

/// Writes to the unified system log (Console.app, `log stream`, sysdiagnoses), one
/// `Logger` per emitter: the emitter is the category, the bundle identifier the subsystem.
///
/// Private entries are logged with `%{private}`: the system shows `<private>` unless a
/// debugger is attached or the device has a logging profile installed.
public struct LogEngineOSLog: LGLogEngine {

    private let subsystem: String
    private let loggers = OSAllocatedUnfairLock<[LGLogEmitter: Logger]>(uncheckedState: [:])

    /// - Parameter subsystem: Defaults to the app's bundle identifier.
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "LGLogKit") {
        self.subsystem = subsystem
    }

    public func log(_ entry: LGLogEntry) {
        let logger = logger(for: entry.emitter)
        // Everything but the emitter (already the category) on one line, so filtering on
        // the level symbol or the file works in Console.
        var text = "\(entry.level.symbol) \(entry.location)"
        if !entry.message.isEmpty { text += " \(entry.message)" }
        if let error = entry.error { text += " | \(error.localizedDescription)" }
        if !entry.infos.isEmpty {
            text += " | " + entry.infos.keys.sorted().map { "\($0)=\(entry.infos[$0]!.description)" }.joined(separator: ", ")
        }
        // The privacy annotation has to be a literal, hence the two calls.
        switch entry.privacy {
        case .public:
            logger.log(level: entry.level.osLogType, "\(text, privacy: .public)")
        case .private:
            logger.log(level: entry.level.osLogType, "\(text, privacy: .private)")
        }
    }

    private func logger(for emitter: LGLogEmitter) -> Logger {
        loggers.withLock { loggers in
            if let logger = loggers[emitter] { return logger }
            let logger = Logger(subsystem: subsystem, category: emitter.rawValue)
            loggers[emitter] = logger
            return logger
        }
    }
}

extension LGLogLevel {
    /// `.fault` is reserved by the system for system-level bugs, so an app's `.error` is
    /// an `OSLogType.error` and a `.warning` a persisted `.default`. `.info` and below
    /// stay in memory unless a debugger or a profile asks for them.
    var osLogType: OSLogType {
        switch self {
        case .error:   .error
        case .warning: .default
        case .info:    .info
        case .debug:   .debug
        case .verbose: .debug
        }
    }
}
