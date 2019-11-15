// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Gnomon",
    platforms: [
      .iOS(.v9), .tvOS(.v9), .macOS(.v10_10)
    ],
    products: [
      .library(name: "Gnomon", targets: ["Gnomon"]),
      .library(name: "GnomonDecodable", targets: ["GnomonDecodable"]),
      .library(name: "GnomonJSON", targets: ["GnomonJSON"]),
      .library(name: "GnomonXML", targets: ["GnomonXML"])
    ],
    dependencies: [
      .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.1")),
      .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.0")),
      .package(url: "https://github.com/tadija/AEXML.git", .upToNextMajor(from: "4.2.0"))
    ],
    targets: [
      .target(name: "Gnomon", dependencies: ["RxSwift"], path: "./Sources/Core"),
      .target(name: "GnomonDecodable", dependencies: ["Gnomon"], path: "./Sources/Decodable"),
      .target(name: "GnomonJSON", dependencies: ["Gnomon", "SwiftyJSON"], path: "./Sources/JSON"),
      .target(name: "GnomonXML", dependencies: ["Gnomon", "AEXML"], path: "./Sources/XML")
    ],
    swiftLanguageVersions: [.v5]
)
