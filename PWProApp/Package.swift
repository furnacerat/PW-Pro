// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PWProApp",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PWProApp", targets: ["PWProApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "PWProApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        )
    ]
)
