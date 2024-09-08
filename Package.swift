// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "curie",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/mobileinf/SwiftCommons.git", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/apple/swift-tools-support-core", .upToNextMajor(from: "0.5.2")),
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
                .product(name: "SCInject", package: "SwiftCommons"),
            ]
        ),
        .testTarget(
            name: "CurieCommandTests",
            dependencies: [
                .target(name: "CurieCommand"),
                .target(name: "CurieCore"),
                .target(name: "CurieCommon"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "SCInject", package: "SwiftCommons"),
            ]
        ),
        .target(
            name: "CurieCore",
            dependencies: [
                .target(name: "CurieCommon"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "SCInject", package: "SwiftCommons"),
            ]
        ),
        .target(
            name: "CurieCoreMocks",
            dependencies: [
                .target(name: "CurieCore"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
            ]
        ),
        .testTarget(
            name: "CurieCoreTests",
            dependencies: [
                .target(name: "CurieCore"),
                .target(name: "CurieCoreMocks"),
                .target(name: "CurieCommonMocks"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "SCInject", package: "SwiftCommons"),
            ]
        ),
        .target(
            name: "CurieCommon",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "SCInject", package: "SwiftCommons"),
            ]
        ),
        .target(
            name: "CurieCommonMocks",
            dependencies: [
                .target(name: "CurieCommon"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "SCInject", package: "SwiftCommons"),
            ]
        ),
    ]
)
