// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Gnomon",
    platforms: [
      .iOS(.v9), .tvOS(.v9), .macOS(.v10_10)
    ],
    products: [
      .library(name: "Core", targets: ["Core"]),
      .library(name: "Decodable", targets: ["Decodable"]),
      .library(name: "JSON", targets: ["JSON"]),
      .library(name: "XML", targets: ["XML"])
    ],
    dependencies: [
      .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.1")),
      .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.0")),
      .package(url: "https://github.com/tadija/AEXML.git", .upToNextMajor(from: "4.2.0"))
    ],
    targets: [
      .target(name: "Core", dependencies: ["RxSwift"]),
      .target(name: "Decodable", dependencies: ["Core"]),
      .target(name: "JSON", dependencies: ["Core", "SwiftyJSON"]),
      .target(name: "XML", dependencies: ["Core", "AEXML"])
    ],
    swiftLanguageVersions: [.v5]
)
