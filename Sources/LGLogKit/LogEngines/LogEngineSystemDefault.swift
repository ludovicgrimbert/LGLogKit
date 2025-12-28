//
//  LogEngineSystemDefault.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

import OSLog

public struct LogEngineSystemDefault: LGLogEngine {
    private let publicLog: StaticString = "%{public}@"
    private let privateLog: StaticString = "%{private}@"
    
    private let subsystem: String = Bundle.main.bundleIdentifier ?? ""
    
    public init() {}
    
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
        let logLocation = "\(file):\(function):\(line)"
        let formattedMsg = "\(level.symbol):\(logLocation) \(message)"
        
        for emitter in emitters {
            os_log(
                publicLog,
                log: OSLog(subsystem: subsystem, category: emitter),
                type: level.asOSLogType(),
                formattedMsg + " " +
                (error?.localizedDescription ?? "") + " " +
                (userInfo?.debugDescription ?? "")
            )
        }
    }
}

extension LGLogLevel {
    func asOSLogType() -> OSLogType {
        switch self {
        case .error:
                .error
        case .warning:
                .fault
        case .info:
                .info
        case .debug:
                .debug
        case .verbose:
                .debug
        }
    }
}
