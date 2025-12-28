// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// If not configured, default global log level is set to ``ADSLogLevel.info``
public final class LGLogManager {
    fileprivate(set) var globalLogLevel: LGLogLevel = .info
    fileprivate(set) var customLogLevels: [LGLogEmitterKey : LGLogLevel] = [:]
    
    // Only include the default Print-LogEngine when in Debug
#if DEBUG
    fileprivate(set) var logEngines: [any LGLogEngine] = [LogEnginePrint()]
#else
    fileprivate(set) var logEngines: [any LGLogEngine] = []
#endif
    
    fileprivate let emitters = LGLogEmitter()
}

extension LGLogManager: LGLogManagerProtocol {
    
    @MainActor
    public func log(
        _ level: LGLogLevel,
        _ emitterKey: [LGLogEmitterKey],
        _ message: String,
        _ error: Error?,
        _ infos: [String: SendableLoselessString]?,
        _ file: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: UInt = #line
    ) {
        guard !logEngines.isEmpty else {
            print("LGLogManager: no logEngines provided, could not log anything")
            return
        }
        
        // Level filtering is happening here
        guard isLevelLoggable(level, emitterKey) else { return }
        
        logEngines.forEach {
            $0.log(
                level,
                emitterKey.map { emitters[keyPath: $0] },
                message,
                error,
                infos,
                file,
                function,
                line
            )
        }
    }
    
    @MainActor
    private func isLevelLoggable(
        _ requestedLevel: LGLogLevel,
        _ emitterKeys: [LGLogEmitterKey]
    ) -> Bool {
        // Start with the strictest log level -> 0
        var allowedLogLevel: LGLogLevel = .error
        
        for emitterKey in emitterKeys {
            // Note: error.rawValue < verbose.rawValue
            allowedLogLevel = max(
                getAllowedLogLevel(for: emitterKey),
                allowedLogLevel
            )
        }
        return requestedLevel <= allowedLogLevel
    }
}

extension LGLogManager: LGLogManagerSettingsProtocol {
    
    public func setGlobal(logLevel: LGLogLevel) {
        self.globalLogLevel = logLevel
    }
    
    public func setCustom(logLevel: LGLogLevel, forEmitter key: LGLogEmitterKey) {
        customLogLevels[key] = logLevel
    }
    
    public func add(logEngines: any LGLogEngine...) {
        self.logEngines.append(contentsOf: logEngines)
    }
    
    public func resetLogEngines() {
        self.logEngines = []
    }
    
    /// Returns the lowest log level priority the emitter is allowed to use.
    ///
    /// The lowest priority being ``LGLogLevel.verbose``
    public func getAllowedLogLevel(for emitterKey: LGLogEmitterKey) -> LGLogLevel {
        if let customLogLevel = customLogLevels[emitterKey] {
            customLogLevel
        } else {
            globalLogLevel
        }
    }
}
