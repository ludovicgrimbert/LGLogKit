//
//  LogEngineFirebase.swift
//  LGLogKitCrashlytics
//
//  Created by Ludovic Grimbert on 27/12/2025.
//

import Foundation
import LGLogKit
import FirebaseCrashlytics

/// Sends entries to Firebase Crashlytics. The app must have called
/// `FirebaseApp.configure()` before the first entry.
///
/// Every entry becomes a breadcrumb (the log attached to the next crash report). Only
/// `.error` entries also become non-fatal issues:
///
/// - with an attached `Error`, that error is recorded as is, so Crashlytics groups the
///   issue by the error's own domain and code (`URLError`, your `PampukoError`…);
/// - without one, a synthetic error with a stable domain per emitter is recorded, so all
///   message-only errors of an emitter land in one issue whose occurrences carry the
///   message. A message in the domain would have created one issue per interpolated value.
///
/// Private entries reach Firebase as `<private>` with their infos dropped; an attached
/// error is still recorded (Crashlytics needs it to build the issue) but its description
/// is not logged.
public struct LogEngineFirebase: LGLogEngine {

    public static let domainPrefix = "LGLogKit"

    public init() {}

    public func log(_ entry: LGLogEntry) {
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.log(entry.redactedLine)

        guard entry.level == .error else { return }

        var userInfo: [String: Any] = entry.redactedInfos.mapValues { $0 as Any }
        userInfo["emitter"] = entry.emitter.rawValue
        userInfo["location"] = entry.location

        if let error = entry.error {
            if !entry.message.isEmpty { userInfo["message"] = entry.redactedMessage }
            crashlytics.record(error: error, userInfo: userInfo)
        } else {
            userInfo[NSLocalizedDescriptionKey] = entry.redactedMessage
            let synthetic = NSError(domain: "\(Self.domainPrefix).\(entry.emitter.rawValue)", code: 0, userInfo: userInfo)
            crashlytics.record(error: synthetic)
        }
    }
}
