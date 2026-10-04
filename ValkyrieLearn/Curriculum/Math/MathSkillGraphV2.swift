import Foundation

public enum MathStrand: String, Codable, CaseIterable, Sendable {
    case numberSense
    case numberComposition
    case addition
    case subtraction
    case placeValue
    case patternsAlgebra
    case geometrySpatial
    case measurementDataTimeMoney
    case reasoning
    case stretch
}

public struct MathSkillDescriptor: Sendable {
    public let definition: SkillDefinition
    public let strand: MathStrand
    public let title: String
    public let developmentalOrder: Int
    public let representations: [Representation]
    public let isStretch: Bool

    public var id: SkillID { definition.id }

    public init(
        id: SkillID,
        strand: MathStrand,
        title: String,
        developmentalOrder: Int,
        prerequisites: [SkillID] = [],
        requiredReadiness: SkillState = .developing,
        representations: [Representation] = [.concrete, .pictorial],
        isStretch: Bool = false
    ) {
        self.definition = SkillDefinition(
            id,
            prerequisites: prerequisites,
            requiredReadiness: requiredReadiness
        )
        self.strand = strand
        self.title = title
        self.developmentalOrder = developmentalOrder
        self.representations = representations
        self.isStretch = isStretch
    }
}

public extension MathSkills {
    // Number sense
    static let oneToOne10 = SkillID(rawValue: "math.numberSense.oneToOne10")
    static let cardinality10 = SkillID(rawValue: "math.numberSense.cardinality10")
    static let numeralQuantity10 = SkillID(rawValue: "math.numberSense.numeralQuantity10")
    static let countTo20 = SkillID(rawValue: "math.numberSense.countTo20")
    static let numberOrder20 = SkillID(rawValue: "math.numberSense.numberOrder20")
    static let oneMoreLess20 = SkillID(rawValue: "math.numberSense.oneMoreLess20")
    static let estimate10 = SkillID(rawValue: "math.numberSense.estimate10")

    // Number composition
    static let compose5 = SkillID(rawValue: "math.composition.compose5")
    static let decompose5 = SkillID(rawValue: "math.composition.decompose5")
    static let compose10 = SkillID(rawValue: "math.composition.compose10")
    static let decompose10 = SkillID(rawValue: "math.composition.decompose10")
    static let make10 = SkillID(rawValue: "math.composition.make10")
    static let doubles10 = SkillID(rawValue: "math.composition.doubles10")

    // Addition
    static let combine5 = SkillID(rawValue: "math.addition.combine5")
    static let addPictures10 = SkillID(rawValue: "math.addition.pictures10")
    static let addSymbols10 = SkillID(rawValue: "math.addition.symbols10")
    static let countOn10 = SkillID(rawValue: "math.addition.countOn10")
    static let addWithin20 = SkillID(rawValue: "math.addition.within20")
    static let storyAddition10 = SkillID(rawValue: "math.addition.story10")

    // Subtraction
    static let takeAway5 = SkillID(rawValue: "math.subtraction.takeAway5")
    static let subtractPictures10 = SkillID(rawValue: "math.subtraction.pictures10")
    static let subtractSymbols10 = SkillID(rawValue: "math.subtraction.symbols10")
    static let findDifference10 = SkillID(rawValue: "math.subtraction.difference10")
    static let inverseFacts10 = SkillID(rawValue: "math.subtraction.inverseFacts10")
    static let subtractWithin20 = SkillID(rawValue: "math.subtraction.within20")

    // Place value
    static let groupTen = SkillID(rawValue: "math.placeValue.groupTen")
    static let buildTwoDigit = SkillID(rawValue: "math.placeValue.buildTwoDigit")
    static let readTwoDigit = SkillID(rawValue: "math.placeValue.readTwoDigit")
    static let compareTwoDigit = SkillID(rawValue: "math.placeValue.compareTwoDigit")
    static let orderTwoDigit = SkillID(rawValue: "math.placeValue.orderTwoDigit")

    // Patterns / early algebra
    static let patternAB = SkillID(rawValue: "math.patterns.ab")
    static let patternAAB = SkillID(rawValue: "math.patterns.aab")
    static let patternABC = SkillID(rawValue: "math.patterns.abc")
    static let patternMissing = SkillID(rawValue: "math.patterns.missing")
    static let patternCreate = SkillID(rawValue: "math.patterns.create")
    static let equivalence10 = SkillID(rawValue: "math.algebra.equivalence10")

    // Geometry / spatial
    static let recognizeShapes = SkillID(rawValue: "math.geometry.recognizeShapes")
    static let shapeAttributes = SkillID(rawValue: "math.geometry.shapeAttributes")
    static let composeShapes = SkillID(rawValue: "math.geometry.composeShapes")
    static let rotateShapes = SkillID(rawValue: "math.geometry.rotateShapes")
    static let symmetry = SkillID(rawValue: "math.geometry.symmetry")
    static let positionalLanguage = SkillID(rawValue: "math.spatial.positionalLanguage")
    static let mapRoute = SkillID(rawValue: "math.spatial.mapRoute")

    // Measurement, data, time, money
    static let compareLength = SkillID(rawValue: "math.measurement.compareLength")
    static let compareWeight = SkillID(rawValue: "math.measurement.compareWeight")
    static let compareCapacity = SkillID(rawValue: "math.measurement.compareCapacity")
    static let nonstandardMeasure = SkillID(rawValue: "math.measurement.nonstandard")
    static let classifyObjects = SkillID(rawValue: "math.data.classifyObjects")
    static let pictureGraph = SkillID(rawValue: "math.data.pictureGraph")
    static let timeDayparts = SkillID(rawValue: "math.time.dayparts")
    static let coinValues = SkillID(rawValue: "math.money.coinValues")

    // Reasoning
    static let explainComparison = SkillID(rawValue: "math.reasoning.explainComparison")
    static let sameTotalDifferentWay = SkillID(rawValue: "math.reasoning.sameTotalDifferentWay")
    static let chooseStrategy = SkillID(rawValue: "math.reasoning.chooseStrategy")
    static let whatChanged = SkillID(rawValue: "math.reasoning.whatChanged")
    static let multipleSolutions = SkillID(rawValue: "math.reasoning.multipleSolutions")
    static let multiStep = SkillID(rawValue: "math.reasoning.multiStep")

    // Readiness-based stretch
    static let equalGroups = SkillID(rawValue: "math.stretch.equalGroups")
    static let repeatedAddition = SkillID(rawValue: "math.stretch.repeatedAddition")
    static let equalSharing = SkillID(rawValue: "math.stretch.equalSharing")
    static let halves = SkillID(rawValue: "math.stretch.halves")
    static let quarters = SkillID(rawValue: "math.stretch.quarters")
}

public enum MathSkillCatalog {
    public static let descriptors: [MathSkillDescriptor] = [
        // Number sense: foundational quantity, counting and relational understanding.
        .init(id: MathSkills.quantity, strand: .numberSense, title: "Recognize Quantities", developmentalOrder: 1),
        .init(id: MathSkills.oneToOne10, strand: .numberSense, title: "One-to-One Counting to 10", developmentalOrder: 2,
              prerequisites: [MathSkills.quantity]),
        .init(id: MathSkills.counting, strand: .numberSense, title: "Count with Cardinality", developmentalOrder: 3,
              prerequisites: [MathSkills.quantity]),
        .init(id: MathSkills.cardinality10, strand: .numberSense, title: "Know the Last Count Tells How Many", developmentalOrder: 4,
              prerequisites: [MathSkills.oneToOne10, MathSkills.counting]),
        .init(id: MathSkills.subitizing, strand: .numberSense, title: "Subitize Small Quantities", developmentalOrder: 5,
              prerequisites: [MathSkills.quantity]),
        .init(id: MathSkills.numeralQuantity10, strand: .numberSense, title: "Match Numerals and Quantities to 10", developmentalOrder: 6,
              prerequisites: [MathSkills.cardinality10]),
        .init(id: MathSkills.countTo20, strand: .numberSense, title: "Count to 20", developmentalOrder: 7,
              prerequisites: [MathSkills.cardinality10]),
        .init(id: MathSkills.numberOrder20, strand: .numberSense, title: "Order Numbers to 20", developmentalOrder: 8,
              prerequisites: [MathSkills.countTo20, MathSkills.numeralQuantity10]),
        .init(id: MathSkills.oneMoreLess20, strand: .numberSense, title: "One More and One Less to 20", developmentalOrder: 9,
              prerequisites: [MathSkills.numberOrder20]),
        .init(id: MathSkills.compare, strand: .numberSense, title: "Compare Quantities", developmentalOrder: 10,
              prerequisites: [MathSkills.counting]),
        .init(id: MathSkills.estimate10, strand: .numberSense, title: "Estimate Small Collections", developmentalOrder: 11,
              prerequisites: [MathSkills.subitizing, MathSkills.compare]),

        // Number composition: part-whole relationships before speed.
        .init(id: MathSkills.compose5, strand: .numberComposition, title: "Compose Numbers to 5", developmentalOrder: 12,
              prerequisites: [MathSkills.cardinality10]),
        .init(id: MathSkills.decompose5, strand: .numberComposition, title: "Decompose Numbers to 5", developmentalOrder: 13,
              prerequisites: [MathSkills.compose5]),
        .init(id: MathSkills.bonds5, strand: .numberComposition, title: "Number Bonds to 5", developmentalOrder: 14,
              prerequisites: [MathSkills.compose5, MathSkills.decompose5, MathSkills.subitizing]),
        .init(id: MathSkills.compose10, strand: .numberComposition, title: "Compose Numbers to 10", developmentalOrder: 15,
              prerequisites: [MathSkills.bonds5]),
        .init(id: MathSkills.decompose10, strand: .numberComposition, title: "Decompose Numbers to 10", developmentalOrder: 16,
              prerequisites: [MathSkills.compose10]),
        .init(id: MathSkills.bonds10, strand: .numberComposition, title: "Number Bonds to 10", developmentalOrder: 17,
              prerequisites: [MathSkills.compose10, MathSkills.decompose10]),
        .init(id: MathSkills.make10, strand: .numberComposition, title: "Make-10 Strategy", developmentalOrder: 18,
              prerequisites: [MathSkills.bonds10]),
        .init(id: MathSkills.doubles10, strand: .numberComposition, title: "Doubles within 10", developmentalOrder: 19,
              prerequisites: [MathSkills.bonds5]),

        // Addition: concrete -> pictorial -> symbolic -> strategy -> application.
        .init(id: MathSkills.combine5, strand: .addition, title: "Combine Groups within 5", developmentalOrder: 20,
              prerequisites: [MathSkills.counting]),
        .init(id: MathSkills.addition, strand: .addition, title: "Add with Objects within 10", developmentalOrder: 21,
              prerequisites: [MathSkills.counting]),
        .init(id: MathSkills.addPictures10, strand: .addition, title: "Add with Pictures within 10", developmentalOrder: 22,
              prerequisites: [MathSkills.addition], representations: [.pictorial, .concrete]),
        .init(id: MathSkills.addSymbols10, strand: .addition, title: "Read and Solve Addition Symbols within 10", developmentalOrder: 23,
              prerequisites: [MathSkills.addPictures10], representations: [.symbolic, .pictorial]),
        .init(id: MathSkills.countOn10, strand: .addition, title: "Count On within 10", developmentalOrder: 24,
              prerequisites: [MathSkills.addition, MathSkills.oneMoreLess20]),
        .init(id: MathSkills.missing, strand: .addition, title: "Missing Addends within 10", developmentalOrder: 25,
              prerequisites: [MathSkills.addition, MathSkills.bonds10], representations: [.concrete, .pictorial, .symbolic]),
        .init(id: MathSkills.storyAddition10, strand: .addition, title: "Addition Story Problems within 10", developmentalOrder: 26,
              prerequisites: [MathSkills.addPictures10], representations: [.story, .pictorial]),
        .init(id: MathSkills.addWithin20, strand: .addition, title: "Add within 20", developmentalOrder: 27,
              prerequisites: [MathSkills.addSymbols10, MathSkills.make10, MathSkills.countOn10],
              representations: [.concrete, .pictorial, .symbolic, .story]),

        // Subtraction.
        .init(id: MathSkills.takeAway5, strand: .subtraction, title: "Take Away within 5", developmentalOrder: 28,
              prerequisites: [MathSkills.counting]),
        .init(id: MathSkills.subtraction, strand: .subtraction, title: "Subtract with Objects within 10", developmentalOrder: 29,
              prerequisites: [MathSkills.counting, MathSkills.addition]),
        .init(id: MathSkills.subtractPictures10, strand: .subtraction, title: "Subtract with Pictures within 10", developmentalOrder: 30,
              prerequisites: [MathSkills.subtraction], representations: [.pictorial, .concrete]),
        .init(id: MathSkills.subtractSymbols10, strand: .subtraction, title: "Read and Solve Subtraction Symbols within 10", developmentalOrder: 31,
              prerequisites: [MathSkills.subtractPictures10], representations: [.symbolic, .pictorial]),
        .init(id: MathSkills.findDifference10, strand: .subtraction, title: "Find the Difference within 10", developmentalOrder: 32,
              prerequisites: [MathSkills.compare, MathSkills.subtraction]),
        .init(id: MathSkills.inverseFacts10, strand: .subtraction, title: "Connect Addition and Subtraction Facts", developmentalOrder: 33,
              prerequisites: [MathSkills.addSymbols10, MathSkills.subtractSymbols10], representations: [.symbolic, .reasoning]),
        .init(id: MathSkills.subtractWithin20, strand: .subtraction, title: "Subtract within 20", developmentalOrder: 34,
              prerequisites: [MathSkills.inverseFacts10, MathSkills.addWithin20]),

        // Place value.
        .init(id: MathSkills.groupTen, strand: .placeValue, title: "Make a Group of Ten", developmentalOrder: 35,
              prerequisites: [MathSkills.countTo20]),
        .init(id: MathSkills.placeValue, strand: .placeValue, title: "Understand Tens and Ones", developmentalOrder: 36,
              prerequisites: [MathSkills.counting, MathSkills.compare]),
        .init(id: MathSkills.buildTwoDigit, strand: .placeValue, title: "Build Two-Digit Numbers", developmentalOrder: 37,
              prerequisites: [MathSkills.placeValue, MathSkills.groupTen]),
        .init(id: MathSkills.readTwoDigit, strand: .placeValue, title: "Read Two-Digit Numbers", developmentalOrder: 38,
              prerequisites: [MathSkills.buildTwoDigit]),
        .init(id: MathSkills.compareTwoDigit, strand: .placeValue, title: "Compare Two-Digit Numbers", developmentalOrder: 39,
              prerequisites: [MathSkills.readTwoDigit, MathSkills.compare]),
        .init(id: MathSkills.orderTwoDigit, strand: .placeValue, title: "Order Two-Digit Numbers", developmentalOrder: 40,
              prerequisites: [MathSkills.compareTwoDigit]),

        // Patterns and early algebra.
        .init(id: MathSkills.patternAB, strand: .patternsAlgebra, title: "Extend AB Patterns", developmentalOrder: 41),
        .init(id: MathSkills.patternAAB, strand: .patternsAlgebra, title: "Extend AAB Patterns", developmentalOrder: 42,
              prerequisites: [MathSkills.patternAB]),
        .init(id: MathSkills.patternABC, strand: .patternsAlgebra, title: "Extend ABC Patterns", developmentalOrder: 43,
              prerequisites: [MathSkills.patternAAB]),
        .init(id: MathSkills.patternMissing, strand: .patternsAlgebra, title: "Find a Missing Pattern Element", developmentalOrder: 44,
              prerequisites: [MathSkills.patternAB]),
        .init(id: MathSkills.patternCreate, strand: .patternsAlgebra, title: "Create a Pattern", developmentalOrder: 45,
              prerequisites: [MathSkills.patternMissing]),
        .init(id: MathSkills.equivalence10, strand: .patternsAlgebra, title: "Understand Equal Expressions within 10", developmentalOrder: 46,
              prerequisites: [MathSkills.addSymbols10, MathSkills.bonds10], representations: [.concrete, .symbolic, .reasoning]),

        // Geometry and spatial reasoning.
        .init(id: MathSkills.recognizeShapes, strand: .geometrySpatial, title: "Recognize Common Shapes", developmentalOrder: 47),
        .init(id: MathSkills.shapeAttributes, strand: .geometrySpatial, title: "Describe Shape Attributes", developmentalOrder: 48,
              prerequisites: [MathSkills.recognizeShapes]),
        .init(id: MathSkills.composeShapes, strand: .geometrySpatial, title: "Compose Shapes", developmentalOrder: 49,
              prerequisites: [MathSkills.recognizeShapes]),
        .init(id: MathSkills.rotateShapes, strand: .geometrySpatial, title: "Mentally Rotate Shapes", developmentalOrder: 50,
              prerequisites: [MathSkills.composeShapes]),
        .init(id: MathSkills.symmetry, strand: .geometrySpatial, title: "Recognize Simple Symmetry", developmentalOrder: 51,
              prerequisites: [MathSkills.shapeAttributes]),
        .init(id: MathSkills.positionalLanguage, strand: .geometrySpatial, title: "Use Position and Direction Words", developmentalOrder: 52,
              prerequisites: [MathSkills.recognizeShapes]),
        .init(id: MathSkills.mapRoute, strand: .geometrySpatial, title: "Follow and Plan a Simple Route", developmentalOrder: 53,
              prerequisites: [MathSkills.positionalLanguage]),

        // Measurement, data, time, money.
        .init(id: MathSkills.compareLength, strand: .measurementDataTimeMoney, title: "Compare Length", developmentalOrder: 54),
        .init(id: MathSkills.compareWeight, strand: .measurementDataTimeMoney, title: "Compare Weight", developmentalOrder: 55),
        .init(id: MathSkills.compareCapacity, strand: .measurementDataTimeMoney, title: "Compare Capacity", developmentalOrder: 56),
        .init(id: MathSkills.nonstandardMeasure, strand: .measurementDataTimeMoney, title: "Measure with Repeated Units", developmentalOrder: 57,
              prerequisites: [MathSkills.compareLength, MathSkills.counting]),
        .init(id: MathSkills.classifyObjects, strand: .measurementDataTimeMoney, title: "Sort and Classify Objects", developmentalOrder: 58),
        .init(id: MathSkills.pictureGraph, strand: .measurementDataTimeMoney, title: "Read a Picture Graph", developmentalOrder: 59,
              prerequisites: [MathSkills.classifyObjects, MathSkills.counting]),
        .init(id: MathSkills.timeDayparts, strand: .measurementDataTimeMoney, title: "Sequence Dayparts and Events", developmentalOrder: 60),
        .init(id: MathSkills.coinValues, strand: .measurementDataTimeMoney, title: "Compare Simple Coin Values", developmentalOrder: 61,
              prerequisites: [MathSkills.numeralQuantity10, MathSkills.compare]),

        // Mathematical reasoning.
        .init(id: MathSkills.explainComparison, strand: .reasoning, title: "Explain Which Quantity Is Greater", developmentalOrder: 62,
              prerequisites: [MathSkills.compare], representations: [.reasoning, .story, .pictorial]),
        .init(id: MathSkills.sameTotalDifferentWay, strand: .reasoning, title: "Make the Same Total a Different Way", developmentalOrder: 63,
              prerequisites: [MathSkills.bonds10], representations: [.concrete, .reasoning, .symbolic]),
        .init(id: MathSkills.reasoning, strand: .reasoning, title: "Find and Fix a Mathematical Mistake", developmentalOrder: 64,
              prerequisites: [MathSkills.addition, MathSkills.subtraction], representations: [.reasoning, .story, .symbolic]),
        .init(id: MathSkills.chooseStrategy, strand: .reasoning, title: "Choose a Useful Strategy", developmentalOrder: 65,
              prerequisites: [MathSkills.addSymbols10, MathSkills.subtractSymbols10], representations: [.reasoning, .story]),
        .init(id: MathSkills.whatChanged, strand: .reasoning, title: "Reason About What Changed", developmentalOrder: 66,
              prerequisites: [MathSkills.reasoning], representations: [.reasoning, .pictorial]),
        .init(id: MathSkills.multipleSolutions, strand: .reasoning, title: "Find More Than One Solution", developmentalOrder: 67,
              prerequisites: [MathSkills.sameTotalDifferentWay], representations: [.reasoning, .concrete, .symbolic]),
        .init(id: MathSkills.multiStep, strand: .reasoning, title: "Solve a Simple Multi-Step Problem", developmentalOrder: 68,
              prerequisites: [MathSkills.storyAddition10, MathSkills.subtractSymbols10, MathSkills.reasoning],
              representations: [.story, .reasoning]),

        // Readiness-based stretch. No age gate: prerequisites are the gate.
        .init(id: MathSkills.equalGroups, strand: .stretch, title: "Build Equal Groups", developmentalOrder: 69,
              prerequisites: [MathSkills.countTo20, MathSkills.addition], isStretch: true),
        .init(id: MathSkills.repeatedAddition, strand: .stretch, title: "Connect Equal Groups to Repeated Addition", developmentalOrder: 70,
              prerequisites: [MathSkills.equalGroups, MathSkills.addWithin20],
              representations: [.concrete, .pictorial, .symbolic], isStretch: true),
        .init(id: MathSkills.equalSharing, strand: .stretch, title: "Share a Quantity Equally", developmentalOrder: 71,
              prerequisites: [MathSkills.countTo20, MathSkills.subtraction], isStretch: true),
        .init(id: MathSkills.halves, strand: .stretch, title: "Recognize and Make Halves", developmentalOrder: 72,
              prerequisites: [MathSkills.equalSharing, MathSkills.composeShapes], isStretch: true),
        .init(id: MathSkills.quarters, strand: .stretch, title: "Recognize and Make Quarters", developmentalOrder: 73,
              prerequisites: [MathSkills.halves], isStretch: true)
    ]

    public static func graph() throws -> SkillGraph {
        try SkillGraph(descriptors.map(\.definition))
    }

    public static func descriptor(for id: SkillID) -> MathSkillDescriptor? {
        descriptors.first { $0.id == id }
    }

    public static func skills(in strand: MathStrand) -> [MathSkillDescriptor] {
        descriptors
            .filter { $0.strand == strand }
            .sorted { $0.developmentalOrder < $1.developmentalOrder }
    }

    public static var stretchSkills: [MathSkillDescriptor] {
        descriptors.filter(\.isStretch)
    }
}
