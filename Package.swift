// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OCWhatsNew",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    // 補足: WhatsNewView はページ送り TabView (.page スタイル) を使用しており、
    // このスタイルは AppKit (macOS) には存在しない。macOS ではバージョン比較ロジック
    // （OCWhatsNew / WhatsNewItem / WhatsNewVersionStoring）のみがビルド対象になる。
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OCWhatsNew",
            targets: ["OCWhatsNew"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OCWhatsNew"
        ),
        .testTarget(
            name: "OCWhatsNewTests",
            dependencies: ["OCWhatsNew"]
        )
    ],
    swiftLanguageModes: [.v6]
)
