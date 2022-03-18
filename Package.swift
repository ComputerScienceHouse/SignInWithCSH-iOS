// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SignInWithCSH",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(
            name: "SignInWithCSH",
            targets: ["SignInWithCSH"]),
    ],
    dependencies: [
        .package(name: "AppAuth", url: "https://github.com/openid/AppAuth-iOS.git", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "SignInWithCSH",
            dependencies: ["AppAuth"])
    ]
)
