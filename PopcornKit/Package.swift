// swift-tools-version:5.5.0
import PackageDescription

let package = Package(
    name: "PopcornKit",
    platforms: [
        .iOS(.v15), .tvOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(name: "PopcornKit", targets: ["PopcornKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.1"),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper", from: "4.2.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.7.2"),
    ],
    targets: [
        .target(
            name: "PopcornKit",
            dependencies: ["SwiftyJSON", "ObjectMapper", "SwiftSoup"],
            path: "Sources"
        )
    ]
)
