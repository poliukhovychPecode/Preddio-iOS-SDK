// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Preddio-iOS-SDK",
    platforms: [.iOS(.v13), .macOS(.v12)],
    products: [
        .library(name: "AWSManager",
                 targets: ["AWSManager"])
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm", from: "2.33.8")
    ],
    targets: [
        .target(
            name: "AWSManager",
            dependencies: [.product(name: "AWSIoT", package: "aws-sdk-ios-spm"),
                           .product(name: "AWSCognitoIdentityProvider", package: "aws-sdk-ios-spm"),
                           .product(name: "AWSSNS", package: "aws-sdk-ios-spm")],
            path: "Sources"
        )
    ]
)
