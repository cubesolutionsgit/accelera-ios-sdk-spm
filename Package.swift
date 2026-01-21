// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Accelera",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "Accelera", targets: ["Accelera"]),
        .library(name: "AcceleraBanners", targets: ["AcceleraBanners"]),
        .library(name: "AcceleraNotifications", targets: ["AcceleraNotifications"])
    ],
    dependencies: [
        .package(url: "https://github.com/divkit/divkit-ios.git", from: "32.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.7.0"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.0")
    ],
    targets: [
        .target(
            name: "Accelera",
            dependencies: [
                    .product(name: "DivKit", package: "divkit-ios"),
                    .product(name: "DivKitExtensions", package: "divkit-ios"),
                    .product(name: "Lottie", package: "lottie-spm"),
                    .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
                ],
                path: "Sources/Modules/all",
                swiftSettings: [
                    .define("ACCELERA_BANNERS_ENABLED"),
                    .define("ACCELERA_NOTIFICATIONS_ENABLED")
                ]
        ),
        .target(
            name: "AcceleraBanners",
            dependencies: [
                .product(name: "DivKit", package: "divkit-ios"),
                .product(name: "DivKitExtensions", package: "divkit-ios"),
                .product(name: "Lottie", package: "lottie-spm")
            ],
            path: "Sources/Modules/banners",
            swiftSettings: [
                .define("ACCELERA_BANNERS_ENABLED")
            ]
        ),
        .target(
            name: "AcceleraNotifications",
            dependencies: [
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ],
            path: "Sources/Modules/notifications",
            swiftSettings: [
                .define("ACCELERA_NOTIFICATIONS_ENABLED")
            ]
        )
    ]
)
