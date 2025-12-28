//
//  LGLogEngine.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

import Foundation

public typealias SendableLoselessString = LosslessStringConvertible & Sendable

public protocol LGLogEngine {
    @MainActor
    func log(
        _ level: LGLogLevel,
        _ emitters: [String],
        _ message: String,
        _ error: Error?,
        _ infos: [String: SendableLoselessString]?,
        _ file: StaticString,
        _ function: StaticString,
        _ line: UInt
    )
}
