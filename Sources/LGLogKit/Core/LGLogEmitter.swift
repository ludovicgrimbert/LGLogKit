//
//  LGLogEmitter.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

/// The part of the app an entry comes from. Each emitter can have its own log level
/// (see ``LGLogger/setLevel(_:for:)``) and becomes the category in the system log.
///
/// Add your own as static members:
///
/// ```swift
/// extension LGLogEmitter {
///     static let payment: LGLogEmitter = "Payment"
/// }
/// LGLogger.shared.log(.info, "Receipt validated", emitter: .payment)
/// ```
public struct LGLogEmitter: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ name: String) { self.rawValue = name }
    public init(stringLiteral value: String) { self.rawValue = value }

    public var description: String { rawValue }

    /// Everything related to the user interface.
    public static let ui: LGLogEmitter = "UI"
    /// How data is transformed and routed: view models, coordinators, use cases…
    public static let business: LGLogEmitter = "Business"
    /// Software Of Unknown Pedigree: third-party libraries.
    public static let soup: LGLogEmitter = "SOUP"
    /// Navigation, routers, deep links.
    public static let nav: LGLogEmitter = "Navigation"
    /// Persistence: SwiftData, Core Data, files, user defaults.
    public static let data: LGLogEmitter = "Data"
    /// Everything related to the network.
    public static let network: LGLogEmitter = "Network"
}
