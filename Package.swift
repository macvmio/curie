// swift-tools-version:5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "curie",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core.git", .upToNextMajor(from: "0.5.2")),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.3")),
    ],
    targets: [
        .executableTarget(
            name: "curie",
            dependencies: [
                .target(name: "CurieCommand"),
            ],
            path: "Sources/Curie"
        ),
        .target(
            name: "CurieCommand",
            dependencies: [
                .target(name: "CurieCore"),
                .target(name: "CurieCommon"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
            ]
        ),
        .target(
            name: "CurieCore",
            dependencies: [
                .target(name: "CurieCommon"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
            ]
        ),
        .target(
            name: "CurieCommon",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
            ]
        ),
    ]
)
