// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "herald-ios-amplitude",
    // macOS is listed so the tests can run with `swift test` on a Mac.
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "HeraldAmplitude", targets: ["HeraldAmplitude"])
    ],
    dependencies: [
        .package(path: "../herald-ios"),
        .package(url: "https://github.com/amplitude/Amplitude-Swift", from: "1.12.0"),
    ],
    targets: [
        .target(
            name: "HeraldAmplitude",
            dependencies: [
                .product(name: "HeraldCore", package: "herald-ios"),
                .product(name: "AmplitudeSwift", package: "Amplitude-Swift"),
            ]
        ),
        .testTarget(
            name: "HeraldAmplitudeTests",
            dependencies: [
                "HeraldAmplitude",
                .product(name: "HeraldTesting", package: "herald-ios"),
            ]
        ),
    ]
)
