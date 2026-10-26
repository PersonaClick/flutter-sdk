// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "personaclick_sdk",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "personaclick-sdk", targets: ["personaclick_sdk"])
    ],
    dependencies: [
        // Keep in step with the dependency in ../personaclick_sdk.podspec.
        .package(url: "https://github.com/personaclick/ios-sdk.git", exact: "3.36.1")
    ],
    targets: [
        .target(
            name: "personaclick_sdk",
            dependencies: [
                .product(name: "PersonaClick", package: "ios-sdk")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
