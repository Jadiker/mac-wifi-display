// swift-tools-version: 5.9
// SPDX-License-Identifier: GPL-3.0-or-later

import PackageDescription

let package = Package(
    name: "ActualWifiBars",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ActualWifiBars", targets: ["ActualWifiBars"])
    ],
    targets: [
        .executableTarget(
            name: "ActualWifiBars",
            path: "Sources/ActualWifiBars"
        )
    ]
)
