// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Preddio-iOS-SDK",
    defaultLocalization: "en",
    platforms: [.iOS(.v13), .macOS(.v12)],
    products: [
        .library(name: "AWSManager",
                 targets: ["AWSManager"]),
        .library(name: "BluetoothManager",
                 targets: ["BluetoothManager"])
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/amplify-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "AWSManager",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSPluginsCore", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift")
            ]
        ),
        .target(name: "BluetoothManager",
                dependencies: [],
                resources: [.process("Resources")])
    ]
)
