//
//  LGLogProvider.swift
//  LGLogKit
//
//  Created by Ludovic Grimbert on 28/12/2025.
//

public struct LGLogProvider {
    @MainActor
    private(set) static var logManager = LGLogManager()
    
    @MainActor
    public static var shared: any LGLogManagerProtocol { logManager }
    
    @MainActor
    public static var settings: any LGLogManagerSettingsProtocol { logManager }
}
