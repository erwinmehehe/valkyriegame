// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ValkyrieLearningCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "LearningCore", targets: ["LearningCore"])],
    targets: [
        .target(name: "LearningCore", path: "ValkyrieLearn",
                exclude: ["App", "Game", "Parent", "Persistence", "Resources", "Tests"],
                sources: ["Learning", "Curriculum/Math", "Curriculum/Literacy", "Curriculum/Puzzle"]),
        .testTarget(name: "LearningCoreTests", dependencies: ["LearningCore"],
                    path: "ValkyrieLearn/Tests/LearningCoreTests")
    ]
)
