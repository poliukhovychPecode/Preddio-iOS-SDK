// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Preddio-iOS-SDK",
    platforms: [.iOS(.v13), .macOS(.v12)],
    products: [
        .library(name: "AWSManager",
                 targets: ["AWSManager"]),
        .library(name: "BluetoothManager",
                 targets: ["BluetoothManager"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "AWSManager",
            dependencies: []
        ),
        .target(name: "BluetoothManager",
               dependencies: [])
    ]
)
