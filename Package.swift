// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageName = "Basement"
let targetName = packageName

let package = Package(
    name: packageName,
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: packageName,
            targets: [targetName]),
    ],
    dependencies: [
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa.git", from: "10.15.0")
    ],
    targets: [
        .target(
            name: targetName,
            dependencies: ["Realm"]),
        .testTarget(
            name: "BasementTests",
            dependencies: ["Basement"]),
    ]
)
