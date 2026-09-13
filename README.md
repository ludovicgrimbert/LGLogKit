# LGLogKit

A small, thread-safe logger for iOS 17+: levels, per-emitter filtering, privacy, and
pluggable engines (console, unified system log, Firebase Crashlytics). Swift 6.

```swift
// The logger and the console / system-log engines. No dependencies.
.package(url: "https://github.com/ludovicgrimbert/LGLogKit", from: "1.0.0")
// products: "LGLogKit", and "LGLogKitCrashlytics" if you want the Firebase engine
```

## Usage

```swift
import LGLogKit

// Once, at launch
LGLogger.shared.level = .info                    // default .info
LGLogger.shared.defaultEmitter = .business       // used when a call names no emitter
LGLogger.shared.add(engine: LogEngineOSLog())    // the console engine is there in Debug already

// Anywhere, from any thread
LGLogger.shared.log(.info, "Schedule loaded", emitter: .network, infos: ["visits": visits.count])
LGLogger.shared.log(error, "Could not save the favourite")           // level .error, error attached
LGLogger.shared.log(.debug, "Session token: \(token)", privacy: .private)
```

Most apps wrap the shared logger in a free function to shorten the call site:

```swift
func log(_ level: LGLogLevel, _ message: @autoclosure () -> String, error: (any Error)? = nil,
         infos: [String: any LGLogInfoValue] = [:], privacy: LGLogPrivacy = .public,
         file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
    LGLogger.shared.log(level, message(), error: error, infos: infos, privacy: privacy,
                        file: file, function: function, line: line)
}
```

### Levels

`error` 🔴 › `warning` 🟠 › `info` 🟡 › `debug` 🔵 › `verbose` ⚪️. An entry is emitted when its
level is at most the level allowed for its emitter. The message is an `@autoclosure`, so a
filtered `log(.verbose, "\(hugeDump)")` costs nothing; use `isEnabled(_:for:)` to skip
preparation work around it.

### Emitters

The part of the app an entry comes from: `ui`, `business`, `soup` (third parties), `nav`,
`data`, `network`, or your own:

```swift
extension LGLogEmitter { static let payment: LGLogEmitter = "Payment" }

LGLogger.shared.setLevel(.verbose, for: .payment)   // chattier than the global level
LGLogger.shared.resetLevel(for: .payment)
```

The emitter is the category in the system log, and the issue domain in Crashlytics.

### Privacy

Mark `.private` anything that identifies the user or holds a secret. The console engine
(Debug only) prints it; the system log redacts it (`<private>` unless a debugger is
attached); Crashlytics receives `<private>` and no infos. Engines get both the raw and the
redacted forms of an entry (`formattedLine` / `redactedLine`) and choose.

## Engines

| Engine | Product | What it does |
|---|---|---|
| `LogEnginePrint` | LGLogKit | `print` with a timestamp. Default engine in Debug, compiled out of Release. |
| `LogEngineOSLog` | LGLogKit | Unified log, one `Logger` per emitter (subsystem = bundle id). `.error` → `.error`, `.warning` → `.default`, the rest `.info`/`.debug`. |
| `LogEngineFirebase` | LGLogKitCrashlytics | Every entry is a breadcrumb. `.error` entries become non-fatals: the attached `Error` when there is one, else a synthetic `LGLogKit.<emitter>` error carrying the message. Call `FirebaseApp.configure()` first. |

Your own engine is one method:

```swift
struct FileEngine: LGLogEngine {
    func log(_ entry: LGLogEntry) { append(entry.formattedLine) }
}
LGLogger.shared.add(engine: FileEngine())
```

Engines run synchronously on the logging thread, after filtering. Hand slow work off
yourself.

## Migrating from 0.x

| 0.x | 1.0 |
|---|---|
| `LGLogProvider.shared` / `.settings` | `LGLogger.shared` |
| `settings.setGlobal(logLevel:)` | `logger.level = ` |
| `settings.setCustom(logLevel:forEmitter:)` | `logger.setLevel(_:for:)` |
| `settings.add(logEngines: a, b)` | `logger.add(engines: [a, b])` |
| `log(level, [\.ui], msg, error, infos)` (8 positional params) | `log(level, msg, emitter: .ui, error:, infos:)` |
| `extension LGLogEmitter { var app: String { "App" } }` + `\.app` | `extension LGLogEmitter { static let app: LGLogEmitter = "App" }` + `.app` |
| `LGLogEngine.log(level, emitters, message, error, infos, file, function, line)` | `LGLogEngine.log(_ entry: LGLogEntry)` |
| `LogEngineSystemDefault` | `LogEngineOSLog` |
| `Task { @MainActor in logger.log(…) }` from background code | just call it |

## Example app

`LGLogKit.xcworkspace` holds the package and `Example/LGLogKitExample`: pick the allowed
level, emit at every level (publicly or privately), attach an error, log from a background
thread, and watch the entries land in an in-app engine, the console and Console.app.

## Development

```sh
xcodebuild test -workspace LGLogKit.xcworkspace -scheme LGLogKit -destination 'platform=iOS Simulator,name=iPhone 17'
```

The `LGLogKit` product has no dependency, but resolving the package fetches the Firebase
SDK for the Crashlytics product; that is the price of keeping both in one repository.
