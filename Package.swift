// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Murchi",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0")
    ],
    targets: [
        .executableTarget(
            name: "Murchi",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Sources/Murchi",
            resources: [
                .copy("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Carbon"),
                .linkedFramework("UserNotifications")
            ]
        )
    ]
)
