//
//  LogEngineFirebase.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 27/12/2025.
//

import Foundation

import LGLogKit
import FirebaseCrashlytics

/// Note: this engine only works when FirebaseCrashlytics exists
public struct LogEngineFirebase: LGLogEngine {
    // swiftlint:disable:next function_parameter_count
    public func log(
        _ level: LGLogLevel,
        _ emitters: [String],
        _ message: String,
        _ error: Error?,
        _ userInfo: [String: SendableLoselessString]?,
        _ file: StaticString,
        _ function: StaticString,
        _ line: UInt
    ) {
        let crashlytics = Crashlytics.crashlytics()
        
        let joinedEmitters = emitters.joined(separator: "|")
        let logLocation = "\(file):\(function):\(line)"
        
        var editableUserInfos = userInfo ?? [:]
        editableUserInfos["emitters"] = joinedEmitters
        
        let errorString: String
        if let error {
            errorString = " " + error.localizedDescription
        } else {
            errorString = ""
        }
        
        let log = "\(level.symbol):\(joinedEmitters):\(logLocation) \(message)\(errorString)"
        crashlytics.log(log)
        if let error {
            crashlytics.record(error: error, userInfo: editableUserInfos)
        } else if level == .error || level == .warning {
            let error = NSError.init(domain: message, code: -9999, userInfo: editableUserInfos)
            crashlytics.record(error: error, userInfo: editableUserInfos)
        }
    }
}
