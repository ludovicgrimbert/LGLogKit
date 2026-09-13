//
//  LogEnginePrint.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

import Foundation

/// Prints every entry to the console, with a timestamp. Compiled out of Release builds:
/// `print` is slow, unfiltered and ends up nowhere useful in production.
///
/// Privacy is ignored here on purpose: the console is the developer's own machine, and
/// seeing the real values is the point of a debug log.
public struct LogEnginePrint: LGLogEngine {

    public init() {}

    public func log(_ entry: LGLogEntry) {
        #if DEBUG
        print("\(Self.timestamp(entry.date)) \(entry.formattedLine)")
        #endif
    }

    static func timestamp(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits)
                .secondFraction(.fractional(3))
        )
    }
}
