//
//  ContentView.swift
//  LGLogKitExample
//
//  Created by Ludovic Grimbert on 27/12/2025.
//

import SwiftUI
import LGLogKit

extension LGLogEmitter {
    static let example: LGLogEmitter = "Example"
}

/// An in-app engine: keeps the entries so the screen can list them. Shows how little a
/// custom engine needs, and that engines are called from the logging thread (hence the
/// hop to the main actor).
@MainActor @Observable
final class LogStore {
    var entries: [LGLogEntry] = []
}

struct StoreEngine: LGLogEngine {
    let store: LogStore
    func log(_ entry: LGLogEntry) {
        Task { @MainActor in store.entries.append(entry) }
    }
}

struct ContentView: View {
    @State private var store = LogStore()
    @State private var level: LGLogLevel = .info
    @State private var isPrivate = false
    @State private var configured = false

    private let logger = LGLogger.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Settings") {
                    Picker("Allowed level", selection: $level) {
                        ForEach(LGLogLevel.allCases, id: \.self) { Text("\($0.symbol) \($0.name)").tag($0) }
                    }
                    .onChange(of: level) { _, new in logger.level = new }
                    Toggle("Private entries", isOn: $isPrivate)
                }

                Section("Emit") {
                    ForEach(LGLogLevel.allCases, id: \.self) { level in
                        Button("\(level.symbol) \(level.name.capitalized)") {
                            logger.log(level, "Tapped \(level.name) at \(Date.now.formatted(date: .omitted, time: .standard))",
                                       emitter: .example, infos: ["taps": store.entries.count + 1],
                                       privacy: isPrivate ? .private : .public)
                        }
                    }
                    Button("🔴 Error with an Error") {
                        logger.log(URLError(.notConnectedToInternet), "Fetching the schedule", emitter: .network)
                    }
                    Button("🔵 Debug from a background thread") {
                        Task.detached {
                            LGLogger.shared.log(.debug, "Hello from \(Thread.isMainThread ? "main" : "background")", emitter: .soup)
                        }
                    }
                }

                Section("Received by the in-app engine (\(store.entries.count))") {
                    ForEach(Array(store.entries.enumerated().reversed()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.redactedLine).font(.caption.monospaced())
                            Text(entry.date.formatted(date: .omitted, time: .standard)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("LGLogKit")
            .toolbar {
                Button("Clear") { store.entries.removeAll() }
            }
        }
        .onAppear {
            guard !configured else { return }
            configured = true
            // Console (Debug) is already there; add the system log and the in-app list.
            logger.add(engines: [LogEngineOSLog(), StoreEngine(store: store)])
            logger.level = level
            logger.defaultEmitter = .example
        }
    }
}

#Preview {
    ContentView()
}
