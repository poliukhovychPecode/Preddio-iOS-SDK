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
        .package(url: "https://github.com/aws-amplify/amplify-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "AWSManager",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSPluginsCore", package: "amplify-swift"),
                .product(name: "AWSAPIPlugin", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                .product(name: "AWSDataStorePlugin", package: "amplify-swift"),
                .product(name: "AWSS3StoragePlugin", package: "amplify-swift"),
                .product(name: "AWSLocationGeoPlugin", package: "amplify-swift"),
                .product(name: "AWSPinpointAnalyticsPlugin", package: "amplify-swift"),
                .product(name: "AWSPinpointPushNotificationsPlugin", package: "amplify-swift"),
                .product(name: "AWSPredictionsPlugin", package: "amplify-swift"),
                .product(name: "CoreMLPredictionsPlugin", package: "amplify-swift"),
                .product(name: "AWSCloudWatchLoggingPlugin", package: "amplify-swift"),
            ],
            path: "Sources"
        )
    ]
)
