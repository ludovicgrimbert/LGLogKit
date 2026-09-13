# Changelog

All notable changes to this package. [Keep a Changelog](https://keepachangelog.com) format,
[SemVer](https://semver.org).

## [1.0.0] - 2026-09-13

First stable release. The API is rebuilt around one `LGLogger` that can be called from
anywhere, synchronously; nothing from 0.x survives unchanged.

### Changed
- `LGLogProvider` / `LGLogManager` / the two `*Protocol`s → `LGLogger` (`Sendable`, lock-based,
  `LGLogger.shared`). No more `@MainActor`: entries reach the engines on the calling thread,
  in order, before `log` returns — a breadcrumb written just before a crash is not lost.
- One `log` signature with labels and defaults, plus an `Error` overload:
  `log(_ level, _ message, emitter:, error:, infos:, privacy:)`. The message is an
  `@autoclosure`: not built when the level is filtered.
- Emitters are string-backed values (`LGLogEmitter`, `ExpressibleByStringLiteral`) declared
  as static members, no longer `KeyPath`s. One emitter per entry; `defaultEmitter` is used
  when none is given.
- Engines receive a single `LGLogEntry` value (`func log(_ entry:)`) and must be `Sendable`.
  `formattedLine` / `redactedLine` do the formatting for them.
- `LogEngineSystemDefault` → `LogEngineOSLog`: one cached `Logger` per emitter, `.warning`
  maps to `.default` instead of `.fault`, private entries use `%{private}`.
- `LogEngineFirebase`: every entry is a breadcrumb; only `.error` entries become non-fatals.
  With an attached error, that error is recorded (grouped by its own domain/code); without
  one, a synthetic `LGLogKit.<emitter>` error carries the message — a message used as the
  domain created one Crashlytics issue per interpolated value.
- Settings: `level`, `setLevel(_:for:)`, `resetLevel(for:)`, `allowedLevel(for:)`,
  `isEnabled(_:for:)`, `add(engine:)`, `add(engines:)`, `removeAllEngines()`, `engines`.

### Added
- `LGLogPrivacy` (`.public` / `.private`) on every entry, with `redactedMessage`,
  `redactedInfos`, `redactedErrorDescription` for remote sinks.
- Swift Testing target (`LGLogKitTests`, 17 tests) with a `SpyEngine`.
- A real example app (levels, emitters, privacy, an in-app engine, a background-thread log).
- README and this changelog.

### Removed
- Multi-emitter entries (`[LGLogEmitterKey]`) and their "most permissive wins" filtering.
- The console message printed on every call when no engine was configured.
- `defaultLocalization` (no resources), the `.DS_Store` files, the `ADS*` comment residue.

## [0.4.0] - 2025-12-29

Last 0.x: `LGLogProvider` + `LGLogManager` on the main actor, `KeyPath` emitters, three
engines (print, `os_log`, Crashlytics).
