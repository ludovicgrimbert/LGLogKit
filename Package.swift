// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LGLogKit",
    platforms: [.iOS(.v17)],
    products: [
        /// The logger, the console and system-log engines. No dependencies.
        .library(name: "LGLogKit", targets: ["LGLogKit"]),
        /// The Crashlytics engine. Pulls the Firebase SDK; only link it if you use it.
        .library(name: "LGLogKitCrashlytics", targets: ["LGLogKitCrashlytics"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.7.0"),
    ],
    targets: [
        .target(name: "LGLogKit"),
        .target(
            name: "LGLogKitCrashlytics",
            dependencies: [
                "LGLogKit",
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
            ]
        ),
        .testTarget(name: "LGLogKitTests", dependencies: ["LGLogKit"]),
    ],
    swiftLanguageModes: [.v6]
)
