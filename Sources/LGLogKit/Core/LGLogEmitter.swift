//
//  ADSLogEmitter.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

public typealias LGLogEmitterKey = KeyPath<LGLogEmitter, String>

/// Add your own emitters by extanding this entity.
///
///     extension ADSLogEmitter {
///         var myEmitter: String { "Name of my emitter in log" }
///     }
///
/// You can now use it with the keypath syntax: `\.myEmitter`
public struct LGLogEmitter: Sendable {
    /// Everything related to the user interface
    public let ui: String = "UI"
    
    /// The portion of an system which determines how
    /// data is transformed or calculated, and how
    /// it is routed to people or software.
    /// Includes ViewModel, Coordinator, Worker...
    public let business: String = "Business"
    
    /// SOUP: Software Of Unknown/Uncertain Pedigree/Provenance
    ///
    /// Basically all thrid party libraries
    public let soup: String = "SOUP"
    
    /// All things related to the navigation.
    /// Includes Router...
    public let nav: String = "Navigation"
    
    /// Everything related to CoreData
    public let data: String = "Data"
    
    /// Everything related to the network
    public let network: String = "Network"
}
