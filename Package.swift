//
//  Package.swift
//
//  Created by Eugen Filipkov on 11/13/19.
//

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
      .target(name: "Core", dependencies: ["RxSwift"], path: "./Sources/Core"),
      .target(name: "Decodable", dependencies: ["Core"], path: "./Sources/Decodable"),
      .target(name: "JSON", dependencies: ["Core", "SwiftyJSON"], path: "./Sources/JSON"),
      .target(name: "XML", dependencies: ["Core", "AEXML"], path: "./Sources/XML")
    ]
)
