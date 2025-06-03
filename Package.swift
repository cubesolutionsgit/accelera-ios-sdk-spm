// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Accelera",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Accelera",
            targets: ["Accelera"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "Accelera",
              dependencies: [
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
              ],
            path: "Sources/Accelera"
        ),
        .testTarget(
            name: "AcceleraTests",
            dependencies: ["Accelera"],
            path: "Tests/AcceleraTests"
        )
    ]
)
