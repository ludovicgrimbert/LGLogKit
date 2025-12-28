//
//  LGLogManagerProtocol.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

import Foundation

/// A protocol defining settings for
/// managing logging behavior within the application.
///
/// Conformers of `LGLogManagerSettings` are responsible for
/// configuring global logging behavior,
/// customizing log levels for specific emitters, and
/// specifying the log engines to be used.
@MainActor
public protocol LGLogManagerSettingsProtocol {
    
    func setGlobal(logLevel: LGLogLevel)
    func setCustom(logLevel: LGLogLevel, forEmitter: LGLogEmitterKey)
    
    func add(logEngines: any LGLogEngine...)
    func resetLogEngines()
    
    /// Gives the log level of reference for a given emitter key
    func getAllowedLogLevel(for emitterKey: LGLogEmitterKey) -> LGLogLevel
}

@MainActor
public protocol LGLogManagerProtocol {
    func log(
        _ level: LGLogLevel,
        _ emitterKey: [LGLogEmitterKey],
        _ message: String,
        _ error: Error?,
        _ infos: [String: SendableLoselessString]?,
        _ file: StaticString,
        _ function: StaticString,
        _ line: UInt
    )
}

public extension LGLogManagerProtocol {
    
    /// Sugar Syntax to the log function.
    ///
    /// It allows:
    /// - omission of file/function/line
    func log(
        _ level: LGLogLevel,
        _ emitterKey: [LGLogEmitterKey],
        _ msg: String,
        _ error: Error?,
        _ userInfo: [String: SendableLoselessString]?,
        _ file: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: UInt = #line
    ) {
        log(level, emitterKey, msg, error, userInfo, file, function, line)
    }
    
    /// Sugar Syntax to the log function.
    ///
    /// It allows:
    /// - omission of error/userInfo
    /// - omission of file/function/line
    func log(
        _ level: LGLogLevel,
        _ emitterKey: [LGLogEmitterKey],
        _ message: String,
        _ file: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: UInt = #line
    ) {
        log(level, emitterKey, message, nil, nil, file, function, line)
    }
    
    /// Sugar Syntax to the log function.
    ///
    /// It allows:
    /// - omission of file/function/line
    /// - single emitterKey instead of an array
    func log(
        _ level: LGLogLevel,
        _ emitterKey: LGLogEmitterKey,
        _ msg: String,
        _ error: Error?,
        _ userInfo: [String: SendableLoselessString]?,
        _ file: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: UInt = #line
    ) {
        log(level, [emitterKey], msg, error, userInfo, file, function, line)
    }
    
    /// Sugar Syntax to the log function.
    ///
    /// It allows:
    /// - omission of error/userInfo
    /// - omission of file/function/line
    /// - single emitterKey instead of an array
    func log(
        _ level: LGLogLevel,
        _ emitterKey: LGLogEmitterKey,
        _ message: String,
        _ file: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: UInt = #line
    ) {
        log(level, emitterKey, message, nil, nil, file, function, line)
    }
}
