// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "curl",
                      platforms: [.iOS(.v11), .macOS(.v10_13)],
                      products: [
                        .library(name: "curl", targets: [ "curl" ]),
                      ],
                      targets: [
                        .binaryTarget(name: "curl", path: "curl.xcframework"),
                      ])
