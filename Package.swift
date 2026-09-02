// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NaturalSpacing",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "NaturalSpacingCore", targets: ["NaturalSpacingCore"]),
        .library(name: "NaturalSpacingUIKit", targets: ["NaturalSpacingUIKit"]),
        .library(name: "NaturalSpacingAppKit", targets: ["NaturalSpacingAppKit"]),
        .library(name: "NaturalSpacingSwiftUI", targets: ["NaturalSpacingSwiftUI"]),
    ],
    targets: [
        .target(
            name: "NaturalSpacingCore",
            path: "packages/swift/Sources/NaturalSpacingCore"
        ),
        .target(
            name: "NaturalSpacingUIKit",
            dependencies: ["NaturalSpacingCore"],
            path: "packages/swift/Sources/NaturalSpacingUIKit"
        ),
        .target(
            name: "NaturalSpacingAppKit",
            dependencies: ["NaturalSpacingCore"],
            path: "packages/swift/Sources/NaturalSpacingAppKit"
        ),
        .target(
            name: "NaturalSpacingSwiftUI",
            dependencies: [
                "NaturalSpacingCore",
                "NaturalSpacingUIKit",
                "NaturalSpacingAppKit",
            ],
            path: "packages/swift/Sources/NaturalSpacingSwiftUI"
        ),
        .testTarget(
            name: "NaturalSpacingCoreTests",
            dependencies: ["NaturalSpacingCore"],
            path: "packages/swift/Tests/NaturalSpacingCoreTests"
        ),
        .testTarget(
            name: "NaturalSpacingAppKitTests",
            dependencies: ["NaturalSpacingAppKit"],
            path: "packages/swift/Tests/NaturalSpacingAppKitTests"
        ),
        .testTarget(
            name: "NaturalSpacingUIKitTests",
            dependencies: ["NaturalSpacingUIKit"],
            path: "packages/swift/Tests/NaturalSpacingUIKitTests"
        ),
        .testTarget(
            name: "NaturalSpacingSwiftUITests",
            dependencies: ["NaturalSpacingSwiftUI"],
            path: "packages/swift/Tests/NaturalSpacingSwiftUITests"
        ),
    ]
)
