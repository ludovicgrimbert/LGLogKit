//
//  LGLoggerTests.swift
//  LGLogKitTests
//

import Foundation
import Testing
@testable import LGLogKit

/// Records what reaches it, from any thread.
final class SpyEngine: LGLogEngine, @unchecked Sendable {
    private let lock = NSLock()
    private var _entries: [LGLogEntry] = []

    var entries: [LGLogEntry] { lock.withLock { _entries } }
    var messages: [String] { entries.map(\.message) }

    func log(_ entry: LGLogEntry) {
        lock.withLock { _entries.append(entry) }
    }
}

private struct DummyError: Error, LocalizedError {
    var errorDescription: String? { "dummy failed" }
}

private extension LGLogEmitter {
    static let payment: LGLogEmitter = "Payment"
}

@Suite("Filtering")
struct FilteringTests {

    @Test("entries above the global level are dropped, the others forwarded in order")
    func globalLevel() {
        let spy = SpyEngine()
        let logger = LGLogger(engines: [spy], level: .info)
        logger.log(.error, "e")
        logger.log(.warning, "w")
        logger.log(.info, "i")
        logger.log(.debug, "d")
        logger.log(.verbose, "v")
        #expect(spy.messages == ["e", "w", "i"])
    }

    @Test("a custom level applies to its emitter only, and can be reset")
    func customLevel() {
        let spy = SpyEngine()
        let logger = LGLogger(engines: [spy], level: .warning)
        logger.setLevel(.verbose, for: .network)
        logger.log(.debug, "network debug", emitter: .network)
        logger.log(.debug, "business debug", emitter: .business)
        logger.setLevel(.error, for: .payment)
        logger.log(.warning, "payment warning", emitter: .payment)
        #expect(spy.messages == ["network debug"])
        #expect(logger.allowedLevel(for: .network) == .verbose)
        #expect(logger.allowedLevel(for: .business) == .warning)

        logger.resetLevel(for: .network)
        #expect(logger.allowedLevel(for: .network) == .warning)
        logger.log(.debug, "gone", emitter: .network)
        #expect(spy.messages == ["network debug"])
    }

    @Test("isEnabled mirrors what log would do")
    func isEnabled() {
        let logger = LGLogger(engines: [SpyEngine()], level: .info)
        logger.setLevel(.debug, for: .data)
        #expect(logger.isEnabled(.info))
        #expect(!logger.isEnabled(.debug))
        #expect(logger.isEnabled(.debug, for: .data))
        #expect(!logger.isEnabled(.verbose, for: .data))
    }

    @Test("the message is not built for a filtered entry")
    func lazyMessage() {
        let logger = LGLogger(engines: [SpyEngine()], level: .error)
        var built = 0
        func expensive() -> String { built += 1; return "expensive" }
        logger.log(.debug, expensive())
        #expect(built == 0)
        logger.log(.error, expensive())
        #expect(built == 1)
    }

    @Test("nothing is built or forwarded without engines")
    func noEngines() {
        let logger = LGLogger(engines: [], level: .verbose)
        var built = 0
        func expensive() -> String { built += 1; return "x" }
        logger.log(.error, expensive())
        #expect(built == 0)
    }

    @Test("levels order from error (most important) to verbose")
    func levelOrder() {
        #expect(LGLogLevel.error < .warning)
        #expect(LGLogLevel.warning < .info)
        #expect(LGLogLevel.info < .debug)
        #expect(LGLogLevel.debug < .verbose)
        #expect(LGLogLevel.allCases == [.error, .warning, .info, .debug, .verbose])
    }
}

@Suite("Entries")
struct EntryTests {

    @Test("the default emitter fills in when none is given, and can be changed")
    func defaultEmitter() {
        let spy = SpyEngine()
        let logger = LGLogger(engines: [spy])
        logger.log(.info, "a")
        logger.defaultEmitter = .payment
        logger.log(.info, "b")
        logger.log(.info, "c", emitter: .ui)
        #expect(spy.entries.map(\.emitter) == [.business, .payment, .ui])
    }

    @Test("the error overload logs at .error with the error attached")
    func errorOverload() {
        let spy = SpyEngine()
        let logger = LGLogger(engines: [spy], level: .error)
        logger.log(DummyError(), "saving")
        logger.log(DummyError())
        let entries = spy.entries
        #expect(entries.count == 2)
        #expect(entries.allSatisfy { $0.level == .error && $0.error is DummyError })
        #expect(entries.map(\.message) == ["saving", ""])
    }

    @Test("an entry carries its call site, infos and privacy")
    func callSite() {
        let spy = SpyEngine()
        let logger = LGLogger(engines: [spy])
        logger.log(.info, "hello", infos: ["count": 3, "id": "abc"], privacy: .private)
        let entry = try! #require(spy.entries.first)
        #expect("\(entry.file)".hasSuffix("LGLoggerTests.swift"))
        #expect("\(entry.function)" == "callSite()")
        #expect(entry.line > 0)
        #expect(entry.location == "\(entry.file):\(entry.function):\(entry.line)")
        #expect(entry.infos.count == 2)
        #expect(entry.infos["count"]?.description == "3")
        #expect(entry.privacy == .private)
    }

    @Test("every engine receives the same entry; removeAllEngines silences the logger")
    func fanOut() {
        let a = SpyEngine(), b = SpyEngine()
        let logger = LGLogger(engines: [a, b])
        logger.log(.warning, "both")
        #expect(a.messages == ["both"] && b.messages == ["both"])
        #expect(a.entries.first?.date == b.entries.first?.date)

        logger.removeAllEngines()
        logger.log(.warning, "none")
        #expect(a.messages == ["both"] && b.messages == ["both"])
        #expect(logger.engines.isEmpty)

        logger.add(engine: a)
        logger.log(.warning, "again")
        #expect(a.messages == ["both", "again"])
    }

    @Test("logging from many threads at once loses nothing")
    func concurrency() async {
        let spy = SpyEngine()
        let logger = LGLogger(engines: [spy], level: .verbose)
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<200 {
                group.addTask { logger.log(.debug, "\(i)", emitter: i.isMultiple(of: 2) ? .ui : .data) }
            }
        }
        #expect(spy.entries.count == 200)
        #expect(Set(spy.messages).count == 200)
    }
}

@Suite("Formatting and redaction")
struct FormattingTests {

    @Test("the formatted line has the level, emitter, location, message, error and sorted infos")
    func formattedLine() {
        let entry = LGLogEntry(level: .error, emitter: .network, message: "load failed",
                               error: DummyError(), infos: ["b": 2, "a": "x"],
                               file: "App/Client.swift", function: "load()", line: 42)
        #expect(entry.formattedLine == "🔴 [Network] App/Client.swift:load():42 load failed | dummy failed | a=x, b=2")
    }

    @Test("empty parts leave no trailing separators")
    func minimalLine() {
        let entry = LGLogEntry(level: .info, emitter: .ui, message: "", file: "F.swift", function: "f()", line: 1)
        #expect(entry.formattedLine == "🟡 [UI] F.swift:f():1")
    }

    @Test("a private entry is redacted for remote sinks, a public one is untouched")
    func redaction() {
        let secret = LGLogEntry(level: .error, emitter: .data, message: "token=abc", error: DummyError(),
                                infos: ["email": "a@b.c"], privacy: .private,
                                file: "F.swift", function: "f()", line: 7)
        #expect(secret.redactedMessage == "<private>")
        #expect(secret.redactedInfos.isEmpty)
        #expect(secret.redactedErrorDescription == "DummyError")
        #expect(secret.redactedLine == "🔴 [Data] F.swift:f():7 <private> | DummyError")
        #expect(secret.formattedLine.contains("token=abc"))

        let open = LGLogEntry(level: .info, emitter: .data, message: "ok", infos: ["n": 1],
                              file: "F.swift", function: "f()", line: 7)
        #expect(open.redactedLine == open.formattedLine)
    }

    @Test("emitters are string-backed and extensible")
    func emitters() {
        #expect(LGLogEmitter.network.rawValue == "Network")
        #expect(LGLogEmitter("Payment") == .payment)
        #expect(LGLogEmitter(rawValue: "UI") == .ui)
        #expect("\(LGLogEmitter.soup)" == "SOUP")
    }

    @Test("levels map onto the system log without using .fault")
    func osLogTypes() {
        #expect(LGLogLevel.error.osLogType == .error)
        #expect(LGLogLevel.warning.osLogType == .default)
        #expect(LGLogLevel.info.osLogType == .info)
        #expect(LGLogLevel.debug.osLogType == .debug)
        #expect(LGLogLevel.verbose.osLogType == .debug)
    }

    @Test("the print engine's timestamp is time-only with milliseconds")
    func timestamp() {
        let stamp = LogEnginePrint.timestamp(Date(timeIntervalSince1970: 0))
        // HH:mm:ss + a locale-dependent fraction separator + 3 digits
        #expect(stamp.count == 12, "\(stamp)")
        #expect(stamp.hasSuffix("000"))
    }
}
