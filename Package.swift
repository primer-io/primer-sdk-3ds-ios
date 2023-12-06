// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Primer3DS",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "Primer3DS", targets: ["Primer3DS"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Primer3DS",
            dependencies: [
                .byName(name: "ThreeDS_SDK")
            ],
            path: "Sources/Primer3DS"
        ),
        .binaryTarget(
            name: "ThreeDS_SDK",
            path: "Sources/Frameworks/ThreeDS_SDK.xcframework")
    ],
    swiftLanguageVersions: [.v5]
)
