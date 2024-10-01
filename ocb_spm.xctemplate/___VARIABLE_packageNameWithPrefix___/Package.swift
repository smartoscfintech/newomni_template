// swift-tools-version: 5.7.1

import PackageDescription

let package = Package(
    name: "___VARIABLE_packageNameWithPrefix___",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "___VARIABLE_packageNameWithPrefix___",
            targets: ["___VARIABLE_packageNameWithPrefix___"]
        ),
        .library(
            name: "___VARIABLE_packageNameWithPrefix___UI",
            targets: ["___VARIABLE_packageNameWithPrefix___UI"]
        )
    ],
    dependencies: [
        .package(path: "../OCBKit"),
        .package(path: "../OCBScreenKit"),
        .package(path: "../NetworkServiceKit"),
        .package(path: "../AnalyticsKit"),
        .package(path: "../DeepLinksKit"),
        .package(path: "../OCBPreferencesKit"),
        .package(path: "../PublicLibs/checkouts/CombineCocoa"),
    ],
    targets: [
        .target(
            name: "___VARIABLE_packageNameWithPrefix___",
            dependencies: [
                .product(name: "OCBKit", package: "OCBKit"),
                "OCBPreferencesKit"
            ]
        ),
        .target(
            name: "___VARIABLE_packageNameWithPrefix___UI",
            dependencies: [
                "___VARIABLE_packageNameWithPrefix___",
                "OCBPreferencesKit",
                "CombineCocoa",
                "AnalyticsKit",
                "DeepLinksKit",
                .product(name: "OCBBaseScreenKit", package: "OCBScreenKit"),
                .product(name: "APIClient", package: "NetworkServiceKit")
            ]
        )
    ]
)
