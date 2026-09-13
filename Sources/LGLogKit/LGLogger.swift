//
//  LGLogger.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

import Foundation
import os

/// Filters entries by level and fans them out to its engines.
///
/// Thread-safe and callable from anywhere, synchronously: an entry reaches the engines
/// before `log` returns, on the calling thread, so ordering is preserved and a breadcrumb
/// written just before a crash is not lost.
///
/// ```swift
/// // At launch
/// LGLogger.shared.level = .info
/// LGLogger.shared.defaultEmitter = .business
/// LGLogger.shared.add(engine: LogEngineOSLog())
///
/// // Anywhere
/// LGLogger.shared.log(.info, "Schedule loaded", emitter: .network, infos: ["count": visits.count])
/// LGLogger.shared.log(error, "Could not save the favourite")
/// LGLogger.shared.log(.debug, "Token: \(token)", privacy: .private)
/// ```
///
/// Without configuration the level is `.info` and the only engine is ``LogEnginePrint``
/// in Debug builds (nothing in Release).
public final class LGLogger: Sendable {

    /// The app-wide logger.
    public static let shared = LGLogger()

    /// What a fresh logger writes to: the console in Debug, nothing in Release.
    public static var defaultEngines: [any LGLogEngine] {
        #if DEBUG
        [LogEnginePrint()]
        #else
        []
        #endif
    }

    private struct State {
        var level: LGLogLevel
        var customLevels: [LGLogEmitter: LGLogLevel] = [:]
        var engines: [any LGLogEngine]
        var defaultEmitter: LGLogEmitter
    }

    private let state: OSAllocatedUnfairLock<State>

    public init(
        engines: [any LGLogEngine] = LGLogger.defaultEngines,
        level: LGLogLevel = .info,
        defaultEmitter: LGLogEmitter = .business
    ) {
        state = OSAllocatedUnfairLock(initialState: State(level: level, engines: engines, defaultEmitter: defaultEmitter))
    }

    // MARK: - Settings

    /// The level allowed for every emitter without a custom level. Default `.info`.
    public var level: LGLogLevel {
        get { state.withLock { $0.level } }
        set { state.withLock { $0.level = newValue } }
    }

    /// The emitter used by `log` calls that do not name one. Default `.business`.
    public var defaultEmitter: LGLogEmitter {
        get { state.withLock { $0.defaultEmitter } }
        set { state.withLock { $0.defaultEmitter = newValue } }
    }

    /// Lets one emitter be chattier or quieter than ``level``.
    public func setLevel(_ level: LGLogLevel, for emitter: LGLogEmitter) {
        state.withLock { $0.customLevels[emitter] = level }
    }

    /// Puts the emitter back on the global ``level``.
    public func resetLevel(for emitter: LGLogEmitter) {
        state.withLock { $0.customLevels[emitter] = nil }
    }

    /// The chattiest level the emitter may use.
    public func allowedLevel(for emitter: LGLogEmitter) -> LGLogLevel {
        state.withLock { $0.customLevels[emitter] ?? $0.level }
    }

    /// Whether an entry at this level would reach the engines — to skip expensive
    /// preparation that a filtered entry would waste. The message itself is already lazy.
    public func isEnabled(_ level: LGLogLevel, for emitter: LGLogEmitter? = nil) -> Bool {
        state.withLock { level <= $0.customLevels[emitter ?? $0.defaultEmitter] ?? $0.level }
    }

    public var engines: [any LGLogEngine] {
        state.withLock { $0.engines }
    }

    public func add(engine: any LGLogEngine) {
        state.withLock { $0.engines.append(engine) }
    }

    public func add(engines: [any LGLogEngine]) {
        state.withLock { $0.engines.append(contentsOf: engines) }
    }

    public func removeAllEngines() {
        state.withLock { $0.engines = [] }
    }

    // MARK: - Logging

    /// Logs a message. The message is only built when the level passes the filter.
    ///
    /// - Parameters:
    ///   - level: Severity; filtered against ``allowedLevel(for:)``.
    ///   - message: What happened. Interpolate freely: it is not evaluated when filtered.
    ///   - emitter: Where it comes from; ``defaultEmitter`` when nil.
    ///   - error: An error to attach. Remote engines record it as a non-fatal when `level` is `.error`.
    ///   - infos: Structured context (identifiers, counts…). Keys are free-form.
    ///   - privacy: Mark `.private` anything that identifies the user or holds a secret.
    public func log(
        _ level: LGLogLevel,
        _ message: @autoclosure () -> String,
        emitter: LGLogEmitter? = nil,
        error: (any Error)? = nil,
        infos: [String: any LGLogInfoValue] = [:],
        privacy: LGLogPrivacy = .public,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        // Snapshot under the lock, then let go of it: engines run outside so that an
        // engine that logs in turn cannot deadlock on the (non-recursive) lock.
        let snapshot: (engines: [any LGLogEngine], emitter: LGLogEmitter)? = state.withLock { state in
            let emitter = emitter ?? state.defaultEmitter
            guard !state.engines.isEmpty,
                  level <= state.customLevels[emitter] ?? state.level else { return nil }
            return (state.engines, emitter)
        }
        guard let snapshot else { return }

        let entry = LGLogEntry(
            level: level, emitter: snapshot.emitter, message: message(), error: error,
            infos: infos, privacy: privacy, file: file, function: function, line: line
        )
        for engine in snapshot.engines {
            engine.log(entry)
        }
    }

    /// Logs an error at the `.error` level, with an optional message giving the context.
    public func log(
        _ error: any Error,
        _ message: @autoclosure () -> String = "",
        emitter: LGLogEmitter? = nil,
        infos: [String: any LGLogInfoValue] = [:],
        privacy: LGLogPrivacy = .public,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.error, message(), emitter: emitter, error: error, infos: infos, privacy: privacy,
            file: file, function: function, line: line)
    }
}
