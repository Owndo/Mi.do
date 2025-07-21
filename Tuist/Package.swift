// swift-tools-version: 5.10
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

let package = Package(
    name: "Tasker-tuist",
    dependencies: [
        .package(url: "https://github.com/PostHog/posthog-ios", .upToNextMajor(from: "3.29.0")),
    ]
)
