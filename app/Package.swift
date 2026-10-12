// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "zidev-app",
    platforms: [.macOS(.v13)],
    dependencies: [.package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0")],
    targets: [.executableTarget(name: "zidev-app", dependencies: ["SwiftTerm"])]
)
