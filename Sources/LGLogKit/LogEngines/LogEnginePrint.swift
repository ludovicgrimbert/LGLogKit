//
//  LogEnginePrint.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

import Foundation

/// Note: this engine only works when compil flag DEBUG is set
public struct LogEnginePrint: LGLogEngine {
    
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
#if DEBUG
        let joinedEmitters = emitters.joined(separator: "|")
        let logLocation = "\(file):\(function):\(line)"
        print(
            Date.now.formatted(
                .dateTime
                    .year(.twoDigits)
                    .month(.twoDigits)
                    .day(.twoDigits)
                    .hour(.twoDigits(amPM: .omitted))
                    .minute(.twoDigits)
                    .second(.twoDigits)
                    .secondFraction(.fractional(3))
            ) +
            ":\(level.symbol):\(joinedEmitters):\(logLocation) \(message)",
            error?.localizedDescription ?? "",
            userInfo ?? ""
        )
#endif
    }
}
