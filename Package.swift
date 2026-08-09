// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReadabilityScoreKit",
    products: [
        .library(name: "ReadabilityScoreKit", targets: ["ReadabilityScoreKit"])
    ],
    targets: [
        .target(name: "ReadabilityScoreKit"),
        .testTarget(
            name: "ReadabilityScoreKitTests",
            dependencies: ["ReadabilityScoreKit"]
        )
    ]
)
