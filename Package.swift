// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FarmRPGBrowser",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "FarmRPGBrowser",
            path: "Sources/FarmRPGBrowser",
            linkerSettings: [
                .linkedFramework("WebKit"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
