// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NaturalSpacingConsumer",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(name: "NaturalSpacing", path: "../../.."),
    ],
    targets: [
        .executableTarget(
            name: "NaturalSpacingConsumer",
            dependencies: [
                .product(name: "NaturalSpacingCore", package: "NaturalSpacing"),
                .product(name: "NaturalSpacingAppKit", package: "NaturalSpacing"),
                .product(name: "NaturalSpacingSwiftUI", package: "NaturalSpacing"),
            ]
        ),
    ]
)
