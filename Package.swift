// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LGLogKit",
    defaultLocalization: "en-US",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LGLogKit",
            targets: ["LGLogKit"]
        ),
        .library(name: "LGLogKitCrashlytics",
                 targets: ["LGLogKitCrashlytics"]),

    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
            .target(
                name: "LGLogKit",
                dependencies: []
            ),
        .target(
            name: "LGLogKitCrashlytics",
            dependencies: [
                "LGLogKit",
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
            ]
        )

    ],
    swiftLanguageModes: [.v6]

)
