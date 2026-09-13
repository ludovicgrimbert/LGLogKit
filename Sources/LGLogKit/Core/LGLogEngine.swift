//
//  LGLogEngine.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

import Foundation

/// A value that can travel in an entry's ``LGLogEntry/infos``: anything with a lossless
/// text form (`String`, numbers, `Bool`, `UUID`…).
public typealias LGLogInfoValue = LosslessStringConvertible & Sendable

/// How far an entry may travel.
///
/// Engines decide what it means for them: the system log redacts private text unless a
/// debugger is attached, remote sinks drop private message and infos altogether. The
/// console engine, which only exists in Debug builds, always prints everything.
public enum LGLogPrivacy: Sendable, Equatable {
    /// Safe to show in system logs and to send to remote services.
    case `public`
    /// Carries user or secret data (identifiers, tokens, e-mail addresses…).
    case `private`
}

/// Everything a log call produced, handed as one value to every ``LGLogEngine``.
public struct LGLogEntry: Sendable {
    public let date: Date
    public let level: LGLogLevel
    public let emitter: LGLogEmitter
    public let message: String
    public let error: (any Error)?
    public let infos: [String: any LGLogInfoValue]
    public let privacy: LGLogPrivacy
    public let file: StaticString
    public let function: StaticString
    public let line: UInt

    public init(
        date: Date = .now,
        level: LGLogLevel,
        emitter: LGLogEmitter,
        message: String,
        error: (any Error)? = nil,
        infos: [String: any LGLogInfoValue] = [:],
        privacy: LGLogPrivacy = .public,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        self.date = date
        self.level = level
        self.emitter = emitter
        self.message = message
        self.error = error
        self.infos = infos
        self.privacy = privacy
        self.file = file
        self.function = function
        self.line = line
    }

    /// `Module/File.swift:function():line`
    public var location: String { "\(file):\(function):\(line)" }

    /// The full entry on one line: `🔴 [Network] App/Client.swift:load():42 message | error | k=v`.
    /// For local sinks; remote ones should prefer ``redactedLine``.
    public var formattedLine: String {
        Self.line(level: level, emitter: emitter, location: location,
                  message: message, error: error?.localizedDescription, infos: infos)
    }

    /// ``formattedLine`` with the message, the error description and the infos replaced
    /// by a marker when the entry is private. Public entries are unchanged.
    public var redactedLine: String {
        Self.line(level: level, emitter: emitter, location: location,
                  message: redactedMessage, error: redactedErrorDescription, infos: redactedInfos)
    }

    /// The message, or `<private>` for a private entry.
    public var redactedMessage: String {
        privacy == .public ? message : "<private>"
    }

    /// The infos, or nothing for a private entry.
    public var redactedInfos: [String: any LGLogInfoValue] {
        privacy == .public ? infos : [:]
    }

    /// The error's description, or only its type for a private entry (descriptions
    /// routinely embed user data: URLs, file names, account identifiers…).
    public var redactedErrorDescription: String? {
        guard let error else { return nil }
        return privacy == .public ? error.localizedDescription : String(describing: type(of: error))
    }

    private static func line(
        level: LGLogLevel, emitter: LGLogEmitter, location: String,
        message: String, error: String?, infos: [String: any LGLogInfoValue]
    ) -> String {
        var line = "\(level.symbol) [\(emitter.rawValue)] \(location)"
        if !message.isEmpty { line += " \(message)" }
        if let error, !error.isEmpty { line += " | \(error)" }
        if !infos.isEmpty {
            line += " | " + infos.keys.sorted().map { "\($0)=\(infos[$0]!.description)" }.joined(separator: ", ")
        }
        return line
    }
}

/// A destination for log entries: the console, the system log, a crash reporter, an
/// in-app list… Add your own by conforming and calling ``LGLogger/add(engine:)``.
///
/// Engines are called synchronously, on the thread that logged, after level filtering;
/// an engine that does slow work should hand it off itself.
public protocol LGLogEngine: Sendable {
    func log(_ entry: LGLogEntry)
}
