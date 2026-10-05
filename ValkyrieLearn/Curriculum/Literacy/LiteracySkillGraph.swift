import Foundation

/// Production literacy progression for Word Garden.
///
/// This graph is intentionally developmental rather than a standards-alignment claim.
/// A separate standards-mapping review is required before attaching named curriculum labels.
public enum LiteracyStrand: String, Codable, CaseIterable, Sendable {
    case phonologicalAwareness
    case phonemicAwareness
    case alphabeticPrinciple
    case decodingEncoding
    case vocabulary
    case comprehension
    case storytelling
    case filipino
}

public enum LiteracyRepresentation: String, Codable, CaseIterable, Sendable {
    case auditory
    case picture
    case letter
    case word
    case sentence
    case story
}

public enum LiteracyResponseMode: String, Codable, CaseIterable, Sendable {
    case listenAndChoose
    case directTouch
    case arrange
    case pictureChoice
    case storySequence
    case creativeChoice
}

public enum WordGardenMechanicID {
    public static let soundFlower = "wordGarden.soundFlower"
    public static let rhymeVine = "wordGarden.rhymeVine"
    public static let syllableBells = "wordGarden.syllableBells"
    public static let letterStones = "wordGarden.letterStones"
    public static let sunmillPair = "wordGarden.sunmillPair"
    public static let seedBlendPath = "wordGarden.seedBlendPath"
    public static let wordBloom = "wordGarden.wordBloom"
    public static let storyLantern = "wordGarden.storyLantern"
    public static let storySeedSequence = "wordGarden.storySeedSequence"
    public static let lumiReach = "wordGarden.lumiReach"
}

public struct LiteracySkillDescriptor: Sendable {
    public let definition: SkillDefinition
    public let strand: LiteracyStrand
    public let title: String
    public let developmentalOrder: Int
    public let representations: [LiteracyRepresentation]
    public let responseModes: [LiteracyResponseMode]
    public let mechanicIDs: [String]
    public let requiresRecordedAudio: Bool
    public let isStretch: Bool

    public var id: SkillID { definition.id }

    public init(
        id: SkillID,
        strand: LiteracyStrand,
        title: String,
        developmentalOrder: Int,
        prerequisites: [SkillID] = [],
        requiredReadiness: SkillState = .developing,
        representations: [LiteracyRepresentation],
        responseModes: [LiteracyResponseMode],
        mechanicIDs: [String],
        requiresRecordedAudio: Bool = false,
        isStretch: Bool = false
    ) {
        definition = SkillDefinition(
            id,
            prerequisites: prerequisites,
            requiredReadiness: requiredReadiness
        )
        self.strand = strand
        self.title = title
        self.developmentalOrder = developmentalOrder
        self.representations = representations
        self.responseModes = responseModes
        self.mechanicIDs = mechanicIDs
        self.requiresRecordedAudio = requiresRecordedAudio
        self.isStretch = isStretch
    }
}

public enum LiteracySkills {
    // Phonological awareness
    public static let sameDifferentSounds = SkillID(rawValue: "literacy.phonological.sameDifferentSounds")
    public static let rhymeRecognition = SkillID(rawValue: "literacy.phonological.rhymeRecognition")
    public static let syllableCount = SkillID(rawValue: "literacy.phonological.syllableCount")
    public static let syllableBlend = SkillID(rawValue: "literacy.phonological.syllableBlend")

    // Phonemic awareness
    public static let beginningSoundMatch = SkillID(rawValue: "literacy.phonemic.beginningSoundMatch")
    public static let endingSoundMatch = SkillID(rawValue: "literacy.phonemic.endingSoundMatch")
    public static let oralBlendTwo = SkillID(rawValue: "literacy.phonemic.oralBlendTwo")
    public static let oralBlendThree = SkillID(rawValue: "literacy.phonemic.oralBlendThree")
    public static let segmentCVC = SkillID(rawValue: "literacy.phonemic.segmentCVC")
    public static let manipulateInitialPhoneme = SkillID(rawValue: "literacy.phonemic.manipulateInitialPhoneme")

    // Alphabetic principle
    public static let visualLetterMatch = SkillID(rawValue: "literacy.alphabet.visualLetterMatch")
    public static let visualPrintSequence = SkillID(rawValue: "literacy.alphabet.visualPrintSequence")
    public static let uppercaseLetterNames = SkillID(rawValue: "literacy.alphabet.uppercaseLetterNames")
    public static let lowercaseLetterNames = SkillID(rawValue: "literacy.alphabet.lowercaseLetterNames")
    public static let commonConsonantSounds = SkillID(rawValue: "literacy.alphabet.commonConsonantSounds")
    public static let shortVowelSounds = SkillID(rawValue: "literacy.alphabet.shortVowelSounds")
    public static let soundLetterMapping = SkillID(rawValue: "literacy.alphabet.soundLetterMapping")

    // Decoding / encoding
    public static let blendVC = SkillID(rawValue: "literacy.decoding.blendVC")
    public static let blendCVC = SkillID(rawValue: "literacy.decoding.blendCVC")
    public static let decodeCVC = SkillID(rawValue: "literacy.decoding.decodeCVC")
    public static let encodeCVC = SkillID(rawValue: "literacy.encoding.encodeCVC")
    public static let wordFamilyTransfer = SkillID(rawValue: "literacy.decoding.wordFamilyTransfer")
    public static let earlyHighFrequencyWords = SkillID(rawValue: "literacy.decoding.earlyHighFrequencyWords")

    // Vocabulary
    public static let pictureWordMeaning = SkillID(rawValue: "literacy.vocabulary.pictureWordMeaning")
    public static let semanticCategories = SkillID(rawValue: "literacy.vocabulary.semanticCategories")
    public static let describeAttributes = SkillID(rawValue: "literacy.vocabulary.describeAttributes")
    public static let simpleContextClues = SkillID(rawValue: "literacy.vocabulary.simpleContextClues")

    // Comprehension
    public static let sentencePictureMatch = SkillID(rawValue: "literacy.comprehension.sentencePictureMatch")
    public static let sequenceThreeEvents = SkillID(rawValue: "literacy.comprehension.sequenceThreeEvents")
    public static let literalStoryRecall = SkillID(rawValue: "literacy.comprehension.literalStoryRecall")
    public static let predictNext = SkillID(rawValue: "literacy.comprehension.predictNext")
    public static let simpleInference = SkillID(rawValue: "literacy.comprehension.simpleInference")

    // Storytelling
    public static let retellBeginningMiddleEnd = SkillID(rawValue: "literacy.storytelling.retellBeginningMiddleEnd")
    public static let createStorySequence = SkillID(rawValue: "literacy.storytelling.createStorySequence")

    // Filipino language experiences
    public static let filipinoOralVocabulary = SkillID(rawValue: "literacy.filipino.oralVocabulary")
    public static let filipinoSyllableAwareness = SkillID(rawValue: "literacy.filipino.syllableAwareness")
    public static let filipinoBeginningSounds = SkillID(rawValue: "literacy.filipino.beginningSounds")
    public static let filipinoSimpleComprehension = SkillID(rawValue: "literacy.filipino.simpleComprehension")
}

public enum LiteracySkillCatalog {
    public static let descriptors: [LiteracySkillDescriptor] = [
        // Sound awareness before print.
        .init(
            id: LiteracySkills.sameDifferentSounds,
            strand: .phonologicalAwareness,
            title: "Hear Same and Different Sounds",
            developmentalOrder: 1,
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.soundFlower],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.rhymeRecognition,
            strand: .phonologicalAwareness,
            title: "Recognize Rhyming Words",
            developmentalOrder: 2,
            prerequisites: [LiteracySkills.sameDifferentSounds],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .directTouch],
            mechanicIDs: [WordGardenMechanicID.rhymeVine],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.syllableCount,
            strand: .phonologicalAwareness,
            title: "Count Syllables in Spoken Words",
            developmentalOrder: 3,
            prerequisites: [LiteracySkills.sameDifferentSounds],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .directTouch],
            mechanicIDs: [WordGardenMechanicID.syllableBells],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.syllableBlend,
            strand: .phonologicalAwareness,
            title: "Blend Spoken Syllables",
            developmentalOrder: 4,
            prerequisites: [LiteracySkills.syllableCount],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .arrange],
            mechanicIDs: [WordGardenMechanicID.syllableBells, WordGardenMechanicID.seedBlendPath],
            requiresRecordedAudio: true
        ),

        // Phonemes are taught and assessed through recorded sound plus direct manipulation.
        .init(
            id: LiteracySkills.beginningSoundMatch,
            strand: .phonemicAwareness,
            title: "Match Beginning Sounds",
            developmentalOrder: 5,
            prerequisites: [LiteracySkills.sameDifferentSounds],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.soundFlower],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.endingSoundMatch,
            strand: .phonemicAwareness,
            title: "Match Ending Sounds",
            developmentalOrder: 6,
            prerequisites: [LiteracySkills.beginningSoundMatch],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.soundFlower],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.oralBlendTwo,
            strand: .phonemicAwareness,
            title: "Blend Two Spoken Sound Parts",
            developmentalOrder: 7,
            prerequisites: [LiteracySkills.sameDifferentSounds],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .arrange],
            mechanicIDs: [WordGardenMechanicID.seedBlendPath],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.oralBlendThree,
            strand: .phonemicAwareness,
            title: "Blend Three Spoken Phonemes",
            developmentalOrder: 8,
            prerequisites: [LiteracySkills.oralBlendTwo],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .arrange],
            mechanicIDs: [WordGardenMechanicID.seedBlendPath],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.segmentCVC,
            strand: .phonemicAwareness,
            title: "Segment CVC Words into Phonemes",
            developmentalOrder: 9,
            prerequisites: [LiteracySkills.oralBlendThree, LiteracySkills.beginningSoundMatch],
            representations: [.auditory, .picture],
            responseModes: [.arrange, .directTouch],
            mechanicIDs: [WordGardenMechanicID.seedBlendPath, WordGardenMechanicID.soundFlower],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.manipulateInitialPhoneme,
            strand: .phonemicAwareness,
            title: "Change an Initial Phoneme to Make a New Word",
            developmentalOrder: 10,
            prerequisites: [LiteracySkills.segmentCVC],
            representations: [.auditory, .picture],
            responseModes: [.arrange, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.seedBlendPath],
            requiresRecordedAudio: true,
            isStretch: true
        ),

        // Visual shape identity can be practiced honestly before recorded letter-name audio exists.
        .init(
            id: LiteracySkills.visualLetterMatch,
            strand: .alphabeticPrinciple,
            title: "Match Printed Letter Shapes",
            developmentalOrder: 10,
            representations: [.letter],
            responseModes: [.directTouch],
            mechanicIDs: [WordGardenMechanicID.letterStones, WordGardenMechanicID.sunmillPair]
        ),
        .init(
            id: LiteracySkills.visualPrintSequence,
            strand: .alphabeticPrinciple,
            title: "Remember and Rebuild Short Printed Patterns",
            developmentalOrder: 11,
            prerequisites: [LiteracySkills.visualLetterMatch],
            representations: [.letter],
            responseModes: [.arrange, .directTouch],
            mechanicIDs: [WordGardenMechanicID.storySeedSequence]
        ),
        .init(
            id: LiteracySkills.uppercaseLetterNames,
            strand: .alphabeticPrinciple,
            title: "Recognize Uppercase Letter Names",
            developmentalOrder: 11,
            prerequisites: [LiteracySkills.visualLetterMatch],
            representations: [.auditory, .letter, .picture],
            responseModes: [.listenAndChoose, .directTouch, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.letterStones],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.lowercaseLetterNames,
            strand: .alphabeticPrinciple,
            title: "Recognize Lowercase Letter Names",
            developmentalOrder: 12,
            prerequisites: [LiteracySkills.uppercaseLetterNames],
            representations: [.auditory, .letter, .picture],
            responseModes: [.listenAndChoose, .directTouch, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.letterStones],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.commonConsonantSounds,
            strand: .alphabeticPrinciple,
            title: "Connect Common Consonants to Their Sounds",
            developmentalOrder: 13,
            prerequisites: [LiteracySkills.beginningSoundMatch, LiteracySkills.lowercaseLetterNames],
            representations: [.auditory, .letter, .picture],
            responseModes: [.listenAndChoose, .directTouch],
            mechanicIDs: [WordGardenMechanicID.letterStones, WordGardenMechanicID.soundFlower],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.shortVowelSounds,
            strand: .alphabeticPrinciple,
            title: "Connect Short Vowels to Their Sounds",
            developmentalOrder: 14,
            prerequisites: [LiteracySkills.oralBlendTwo, LiteracySkills.lowercaseLetterNames],
            representations: [.auditory, .letter, .picture],
            responseModes: [.listenAndChoose, .directTouch],
            mechanicIDs: [WordGardenMechanicID.letterStones],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.soundLetterMapping,
            strand: .alphabeticPrinciple,
            title: "Map Spoken Phonemes to Letters",
            developmentalOrder: 15,
            prerequisites: [LiteracySkills.commonConsonantSounds, LiteracySkills.shortVowelSounds],
            representations: [.auditory, .letter],
            responseModes: [.listenAndChoose, .arrange],
            mechanicIDs: [WordGardenMechanicID.letterStones],
            requiresRecordedAudio: true
        ),

        // Decoding and encoding.
        .init(
            id: LiteracySkills.blendVC,
            strand: .decodingEncoding,
            title: "Blend VC Letter Sequences",
            developmentalOrder: 16,
            prerequisites: [LiteracySkills.soundLetterMapping, LiteracySkills.oralBlendTwo],
            representations: [.auditory, .letter, .word],
            responseModes: [.listenAndChoose, .arrange],
            mechanicIDs: [WordGardenMechanicID.seedBlendPath, WordGardenMechanicID.letterStones],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.blendCVC,
            strand: .decodingEncoding,
            title: "Blend CVC Letter Sequences",
            developmentalOrder: 17,
            prerequisites: [LiteracySkills.blendVC, LiteracySkills.oralBlendThree],
            representations: [.auditory, .letter, .word],
            responseModes: [.listenAndChoose, .arrange],
            mechanicIDs: [WordGardenMechanicID.seedBlendPath, WordGardenMechanicID.wordBloom],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.decodeCVC,
            strand: .decodingEncoding,
            title: "Decode Simple CVC Words",
            developmentalOrder: 18,
            prerequisites: [LiteracySkills.blendCVC],
            representations: [.word, .picture, .auditory],
            responseModes: [.pictureChoice, .directTouch],
            mechanicIDs: [WordGardenMechanicID.wordBloom, WordGardenMechanicID.soundFlower],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.encodeCVC,
            strand: .decodingEncoding,
            title: "Build Simple CVC Words from Sounds",
            developmentalOrder: 19,
            prerequisites: [LiteracySkills.segmentCVC, LiteracySkills.soundLetterMapping],
            representations: [.auditory, .letter, .word],
            responseModes: [.arrange, .directTouch],
            mechanicIDs: [WordGardenMechanicID.letterStones, WordGardenMechanicID.seedBlendPath],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.wordFamilyTransfer,
            strand: .decodingEncoding,
            title: "Transfer a Known Pattern to a New CVC Word",
            developmentalOrder: 20,
            prerequisites: [LiteracySkills.decodeCVC, LiteracySkills.encodeCVC],
            representations: [.word, .letter],
            responseModes: [.arrange, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.wordBloom],
            isStretch: true
        ),
        .init(
            id: LiteracySkills.earlyHighFrequencyWords,
            strand: .decodingEncoding,
            title: "Recognize Early High-Frequency Words in Context",
            developmentalOrder: 21,
            prerequisites: [LiteracySkills.decodeCVC],
            representations: [.word, .sentence],
            responseModes: [.directTouch, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.wordBloom, WordGardenMechanicID.storyLantern]
        ),

        // Vocabulary can grow in parallel with decoding.
        .init(
            id: LiteracySkills.pictureWordMeaning,
            strand: .vocabulary,
            title: "Connect Spoken Words with Picture Meanings",
            developmentalOrder: 22,
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.wordBloom, WordGardenMechanicID.lumiReach]
        ),
        .init(
            id: LiteracySkills.semanticCategories,
            strand: .vocabulary,
            title: "Group Words by Meaning",
            developmentalOrder: 23,
            prerequisites: [LiteracySkills.pictureWordMeaning],
            representations: [.picture, .word],
            responseModes: [.arrange, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.wordBloom]
        ),
        .init(
            id: LiteracySkills.describeAttributes,
            strand: .vocabulary,
            title: "Use Attributes to Distinguish Word Meanings",
            developmentalOrder: 24,
            prerequisites: [LiteracySkills.semanticCategories],
            representations: [.picture, .word, .sentence],
            responseModes: [.pictureChoice, .directTouch],
            mechanicIDs: [WordGardenMechanicID.wordBloom, WordGardenMechanicID.storyLantern]
        ),
        .init(
            id: LiteracySkills.sentencePictureMatch,
            strand: .comprehension,
            title: "Match a Simple Sentence to Its Meaning",
            developmentalOrder: 25,
            prerequisites: [LiteracySkills.pictureWordMeaning],
            representations: [.sentence, .picture],
            responseModes: [.pictureChoice, .directTouch],
            mechanicIDs: [WordGardenMechanicID.storyLantern]
        ),
        .init(
            id: LiteracySkills.simpleContextClues,
            strand: .vocabulary,
            title: "Use a Simple Context Clue to Infer Word Meaning",
            developmentalOrder: 26,
            prerequisites: [LiteracySkills.pictureWordMeaning, LiteracySkills.sentencePictureMatch],
            representations: [.sentence, .picture, .story],
            responseModes: [.pictureChoice, .storySequence],
            mechanicIDs: [WordGardenMechanicID.storyLantern, WordGardenMechanicID.wordBloom],
            isStretch: true
        ),

        // Comprehension and narrative.
        .init(
            id: LiteracySkills.sequenceThreeEvents,
            strand: .comprehension,
            title: "Sequence Three Story Events",
            developmentalOrder: 27,
            prerequisites: [LiteracySkills.sentencePictureMatch],
            representations: [.story, .picture, .sentence],
            responseModes: [.storySequence, .arrange],
            mechanicIDs: [WordGardenMechanicID.storyLantern]
        ),
        .init(
            id: LiteracySkills.literalStoryRecall,
            strand: .comprehension,
            title: "Recall Explicit Story Information",
            developmentalOrder: 28,
            prerequisites: [LiteracySkills.sequenceThreeEvents],
            representations: [.story, .picture],
            responseModes: [.pictureChoice, .storySequence],
            mechanicIDs: [WordGardenMechanicID.storyLantern]
        ),
        .init(
            id: LiteracySkills.predictNext,
            strand: .comprehension,
            title: "Predict What May Happen Next",
            developmentalOrder: 29,
            prerequisites: [LiteracySkills.literalStoryRecall],
            representations: [.story, .picture],
            responseModes: [.pictureChoice, .creativeChoice],
            mechanicIDs: [WordGardenMechanicID.storyLantern, WordGardenMechanicID.lumiReach]
        ),
        .init(
            id: LiteracySkills.simpleInference,
            strand: .comprehension,
            title: "Make a Simple Story Inference",
            developmentalOrder: 30,
            prerequisites: [LiteracySkills.predictNext, LiteracySkills.describeAttributes],
            representations: [.story, .picture, .sentence],
            responseModes: [.pictureChoice, .creativeChoice],
            mechanicIDs: [WordGardenMechanicID.storyLantern],
            isStretch: true
        ),
        .init(
            id: LiteracySkills.retellBeginningMiddleEnd,
            strand: .storytelling,
            title: "Retell a Story as Beginning, Middle, and End",
            developmentalOrder: 31,
            prerequisites: [LiteracySkills.literalStoryRecall],
            representations: [.story, .picture],
            responseModes: [.storySequence, .arrange],
            mechanicIDs: [WordGardenMechanicID.storyLantern]
        ),
        .init(
            id: LiteracySkills.createStorySequence,
            strand: .storytelling,
            title: "Create a Coherent Three-Part Story",
            developmentalOrder: 32,
            prerequisites: [LiteracySkills.retellBeginningMiddleEnd, LiteracySkills.predictNext],
            representations: [.story, .picture],
            responseModes: [.creativeChoice, .storySequence],
            mechanicIDs: [WordGardenMechanicID.storyLantern, WordGardenMechanicID.lumiReach],
            isStretch: true
        ),

        // Filipino experiences are a parallel language path, not a translation-only skin.
        .init(
            id: LiteracySkills.filipinoOralVocabulary,
            strand: .filipino,
            title: "Understand Familiar Filipino Words in Context",
            developmentalOrder: 33,
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.wordBloom, WordGardenMechanicID.lumiReach]
        ),
        .init(
            id: LiteracySkills.filipinoSyllableAwareness,
            strand: .filipino,
            title: "Hear Syllables in Familiar Filipino Words",
            developmentalOrder: 34,
            prerequisites: [LiteracySkills.filipinoOralVocabulary],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .directTouch],
            mechanicIDs: [WordGardenMechanicID.syllableBells],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.filipinoBeginningSounds,
            strand: .filipino,
            title: "Match Beginning Sounds in Familiar Filipino Words",
            developmentalOrder: 35,
            prerequisites: [LiteracySkills.filipinoSyllableAwareness],
            representations: [.auditory, .picture],
            responseModes: [.listenAndChoose, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.soundFlower],
            requiresRecordedAudio: true
        ),
        .init(
            id: LiteracySkills.filipinoSimpleComprehension,
            strand: .filipino,
            title: "Understand a Short Filipino Story or Instruction",
            developmentalOrder: 36,
            prerequisites: [LiteracySkills.filipinoOralVocabulary],
            representations: [.story, .picture, .auditory],
            responseModes: [.pictureChoice, .storySequence],
            mechanicIDs: [WordGardenMechanicID.storyLantern, WordGardenMechanicID.lumiReach]
        )
    ]

    public static var stretchSkills: [LiteracySkillDescriptor] {
        descriptors.filter(\.isStretch)
    }

    public static func descriptor(for id: SkillID) -> LiteracySkillDescriptor? {
        descriptors.first { $0.id == id }
    }

    public static func graph() throws -> SkillGraph {
        try SkillGraph(descriptors.map(\.definition))
    }
}

public struct LiteracyPlacementProbe: Identifiable, Equatable, Sendable {
    public let id: String
    public let band: Int
    public let skillID: SkillID
    public let responseMode: LiteracyResponseMode
    public let mechanicID: String
    public let promptIntent: String
    public let requiresRecordedAudio: Bool

    public init(
        id: String,
        band: Int,
        skillID: SkillID,
        responseMode: LiteracyResponseMode,
        mechanicID: String,
        promptIntent: String,
        requiresRecordedAudio: Bool = false
    ) {
        self.id = id
        self.band = max(0, band)
        self.skillID = skillID
        self.responseMode = responseMode
        self.mechanicID = mechanicID
        self.promptIntent = promptIntent
        self.requiresRecordedAudio = requiresRecordedAudio
    }
}

public enum LiteracyPlacement {
    /// Hidden placement blueprint for the eventual Word Garden runtime.
    ///
    /// These probes define *what* to sample and how the child can respond through
    /// direct touch. They deliberately do not depend on speech recognition.
    public static let probes: [LiteracyPlacementProbe] = [
        .init(
            id: "literacy-place-sounds",
            band: 1,
            skillID: LiteracySkills.sameDifferentSounds,
            responseMode: .listenAndChoose,
            mechanicID: WordGardenMechanicID.soundFlower,
            promptIntent: "Choose the flower that starts with the same sound.",
            requiresRecordedAudio: true
        ),
        .init(
            id: "literacy-place-syllables",
            band: 2,
            skillID: LiteracySkills.syllableCount,
            responseMode: .directTouch,
            mechanicID: WordGardenMechanicID.syllableBells,
            promptIntent: "Ring one bell for each spoken syllable.",
            requiresRecordedAudio: true
        ),
        .init(
            id: "literacy-place-beginning",
            band: 3,
            skillID: LiteracySkills.beginningSoundMatch,
            responseMode: .pictureChoice,
            mechanicID: WordGardenMechanicID.soundFlower,
            promptIntent: "Choose the picture with the same beginning sound.",
            requiresRecordedAudio: true
        ),
        .init(
            id: "literacy-place-letter-sound",
            band: 4,
            skillID: LiteracySkills.commonConsonantSounds,
            responseMode: .listenAndChoose,
            mechanicID: WordGardenMechanicID.letterStones,
            promptIntent: "Choose the letter stone for the sound you hear.",
            requiresRecordedAudio: true
        ),
        .init(
            id: "literacy-place-blend",
            band: 5,
            skillID: LiteracySkills.oralBlendThree,
            responseMode: .arrange,
            mechanicID: WordGardenMechanicID.seedBlendPath,
            promptIntent: "Join three sound seeds and choose the picture they make.",
            requiresRecordedAudio: true
        ),
        .init(
            id: "literacy-place-cvc",
            band: 6,
            skillID: LiteracySkills.decodeCVC,
            responseMode: .pictureChoice,
            mechanicID: WordGardenMechanicID.wordBloom,
            promptIntent: "Open the picture bloom that matches the CVC word."
        ),
        .init(
            id: "literacy-place-sentence",
            band: 7,
            skillID: LiteracySkills.sentencePictureMatch,
            responseMode: .pictureChoice,
            mechanicID: WordGardenMechanicID.storyLantern,
            promptIntent: "Choose the scene that matches the short sentence."
        ),
        .init(
            id: "literacy-place-story",
            band: 8,
            skillID: LiteracySkills.literalStoryRecall,
            responseMode: .storySequence,
            mechanicID: WordGardenMechanicID.storyLantern,
            promptIntent: "After a short story beat, restore what happened."
        ),
        .init(
            id: "literacy-place-inference",
            band: 9,
            skillID: LiteracySkills.simpleInference,
            responseMode: .pictureChoice,
            mechanicID: WordGardenMechanicID.storyLantern,
            promptIntent: "Use a story clue to choose what is probably true."
        )
    ]
}


// MARK: - Hidden literacy placement

public struct LiteracyPlacementResult: Equatable, Sendable {
    public let outcome: Outcome
    public let supportLevel: SupportLevel
    public let easySuccess: Bool

    public init(
        outcome: Outcome,
        supportLevel: SupportLevel = .independent,
        easySuccess: Bool = false
    ) {
        self.outcome = outcome
        self.supportLevel = supportLevel
        self.easySuccess = easySuccess
    }
}

public enum LiteracyPlacementResponse: Equatable, Sendable {
    case independentSuccess
    case supportedSuccess
    case struggle

    public init(_ result: LiteracyPlacementResult) {
        if result.outcome == .correct && result.supportLevel == .independent {
            self = .independentSuccess
        } else if result.outcome == .correct {
            self = .supportedSuccess
        } else {
            self = .struggle
        }
    }
}

public struct LiteracyPlacementSession: Codable, Equatable, Sendable {
    public fileprivate(set) var nextBand: Int
    public fileprivate(set) var attemptedProbeIDs: Set<String>
    public fileprivate(set) var highestIndependentBand: Int?
    public fileprivate(set) var firstSupportNeededBand: Int?
    public fileprivate(set) var completedProbeCount: Int
    public fileprivate(set) var isComplete: Bool

    public init(startBand: Int = 3) {
        nextBand = max(0, startBand)
        attemptedProbeIDs = []
        highestIndependentBand = nil
        firstSupportNeededBand = nil
        completedProbeCount = 0
        isComplete = false
    }
}

public struct LiteracyPlacementRecommendation: Equatable, Sendable {
    public let suggestedBand: Int
    public let suggestedSkillID: SkillID?
    public let confidence: PlacementConfidence
    public let highestIndependentBand: Int?
    public let firstSupportNeededBand: Int?

    public init(
        suggestedBand: Int,
        suggestedSkillID: SkillID?,
        confidence: PlacementConfidence,
        highestIndependentBand: Int?,
        firstSupportNeededBand: Int?
    ) {
        self.suggestedBand = suggestedBand
        self.suggestedSkillID = suggestedSkillID
        self.confidence = confidence
        self.highestIndependentBand = highestIndependentBand
        self.firstSupportNeededBand = firstSupportNeededBand
    }
}

/// Adaptive diagnostic controller for Word Garden.
///
/// Placement remains separate from mastery:
/// - begins above the most basic sound discrimination by default
/// - jumps two bands after an easy independent success
/// - advances one band after other independent success
/// - steps back after support or an incorrect response
/// - marks prerequisite closure only as provisional placement readiness
/// - stops once the learner's independent ceiling is bracketed or the probe budget is used
public struct LiteracyPlacementEngine: Sendable {
    public let probes: [LiteracyPlacementProbe]
    public let maxProbes: Int

    private let minBand: Int
    private let maxBand: Int

    public init(
        probes: [LiteracyPlacementProbe] = LiteracyPlacement.probes,
        maxProbes: Int = 6
    ) {
        self.probes = probes.sorted {
            $0.band == $1.band ? $0.id < $1.id : $0.band < $1.band
        }
        self.maxProbes = max(1, maxProbes)
        minBand = self.probes.map(\.band).min() ?? 0
        maxBand = self.probes.map(\.band).max() ?? 0
    }

    public func begin(startBand: Int = 3) -> LiteracyPlacementSession {
        LiteracyPlacementSession(startBand: clamped(startBand))
    }

    public func nextProbe(for session: LiteracyPlacementSession) -> LiteracyPlacementProbe? {
        guard !session.isComplete else { return nil }

        let remaining = probes.filter { !session.attemptedProbeIDs.contains($0.id) }
        guard !remaining.isEmpty else { return nil }

        let desired = clamped(session.nextBand)
        return remaining.min {
            let leftDistance = abs($0.band - desired)
            let rightDistance = abs($1.band - desired)
            if leftDistance == rightDistance { return $0.band < $1.band }
            return leftDistance < rightDistance
        }
    }

    public func record(
        _ result: LiteracyPlacementResult,
        for probe: LiteracyPlacementProbe,
        in session: inout LiteracyPlacementSession,
        profile: inout LearnerProfile,
        graph: SkillGraph
    ) {
        guard !session.isComplete,
              !session.attemptedProbeIDs.contains(probe.id),
              probes.contains(where: { $0.id == probe.id && $0.skillID == probe.skillID }) else {
            return
        }

        session.attemptedProbeIDs.insert(probe.id)
        session.completedProbeCount += 1

        switch LiteracyPlacementResponse(result) {
        case .independentSuccess:
            session.highestIndependentBand = max(
                session.highestIndependentBand ?? probe.band,
                probe.band
            )
            session.nextBand = probe.band + (result.easySuccess ? 2 : 1)
            profile.markPlacementReady(
                graph.prerequisiteClosure(including: probe.skillID)
            )

        case .supportedSuccess, .struggle:
            session.firstSupportNeededBand = min(
                session.firstSupportNeededBand ?? probe.band,
                probe.band
            )
            session.nextBand = probe.band - 1
        }

        session.nextBand = clamped(session.nextBand)
        session.isComplete = shouldComplete(session)
    }

    public func recommendation(
        for session: LiteracyPlacementSession
    ) -> LiteracyPlacementRecommendation {
        let suggestedBand: Int
        if let supportBand = session.firstSupportNeededBand {
            suggestedBand = clamped(supportBand)
        } else if let independentBand = session.highestIndependentBand {
            suggestedBand = clamped(independentBand + 1)
        } else {
            suggestedBand = minBand
        }

        let nearestSkill = probes.min {
            let leftDistance = abs($0.band - suggestedBand)
            let rightDistance = abs($1.band - suggestedBand)
            if leftDistance == rightDistance { return $0.band < $1.band }
            return leftDistance < rightDistance
        }?.skillID

        let bracketed = session.highestIndependentBand.flatMap { high in
            session.firstSupportNeededBand.map { $0 <= high + 1 }
        } ?? false

        let confidence: PlacementConfidence
        if bracketed
            || session.highestIndependentBand == maxBand
            || session.completedProbeCount >= maxProbes {
            confidence = .high
        } else if session.completedProbeCount >= 3 {
            confidence = .medium
        } else {
            confidence = .low
        }

        return LiteracyPlacementRecommendation(
            suggestedBand: suggestedBand,
            suggestedSkillID: nearestSkill,
            confidence: confidence,
            highestIndependentBand: session.highestIndependentBand,
            firstSupportNeededBand: session.firstSupportNeededBand
        )
    }

    private func shouldComplete(_ session: LiteracyPlacementSession) -> Bool {
        if session.completedProbeCount >= maxProbes { return true }
        if session.highestIndependentBand == maxBand { return true }
        if let high = session.highestIndependentBand,
           let support = session.firstSupportNeededBand,
           support <= high + 1,
           session.completedProbeCount >= 2 {
            return true
        }
        return session.attemptedProbeIDs.count >= probes.count
    }

    private func clamped(_ band: Int) -> Int {
        min(max(band, minBand), maxBand)
    }
}


// MARK: - Puzzle Palace v2 curriculum foundation

/// Developmental executive-function and reasoning graph for Puzzle Palace.
///
/// This is a product skill graph, not a claim of formal standards alignment.
/// Skills are intentionally separated so evidence from a pattern task cannot
/// masquerade as working-memory, inhibition, rotation, planning, or debugging mastery.
public enum PuzzleStrand: String, Codable, CaseIterable, Hashable, Sendable {
    case workingMemory
    case inhibitoryControl
    case cognitiveFlexibility
    case patterns
    case spatialReasoning
    case sorting
    case planning
    case sequencing
    case debugging
}

public enum PuzzleRepresentation: String, Codable, CaseIterable, Sendable {
    case rune
    case object
    case path
    case rotation
    case command
}

public enum PuzzleResponseMode: String, Codable, CaseIterable, Sendable {
    case directTouch
    case arrange
    case holdAndRelease
    case route
    case switchRule
    case debug
}

public enum PuzzlePalaceMechanicID {
    public static let runeGate = "puzzlePalace.runeGate"
    public static let memoryBridge = "puzzlePalace.memoryBridge"
    public static let stopGoOrbs = "puzzlePalace.stopGoOrbs"
    public static let sortingPedestal = "puzzlePalace.sortingPedestal"
    public static let mirrorHall = "puzzlePalace.mirrorHall"
    public static let pathTiles = "puzzlePalace.pathTiles"
    public static let commandGears = "puzzlePalace.commandGears"
    public static let bugLantern = "puzzlePalace.bugLantern"
    public static let tikoReach = "puzzlePalace.tikoReach"
}

public struct PuzzleSkillDescriptor: Sendable {
    public let definition: SkillDefinition
    public let strand: PuzzleStrand
    public let title: String
    public let developmentalOrder: Int
    public let representations: [PuzzleRepresentation]
    public let responseModes: [PuzzleResponseMode]
    public let mechanicIDs: [String]
    public let isStretch: Bool

    public var id: SkillID { definition.id }

    public init(
        id: SkillID,
        strand: PuzzleStrand,
        title: String,
        developmentalOrder: Int,
        prerequisites: [SkillID] = [],
        requiredReadiness: SkillState = .developing,
        representations: [PuzzleRepresentation],
        responseModes: [PuzzleResponseMode],
        mechanicIDs: [String],
        isStretch: Bool = false
    ) {
        definition = SkillDefinition(
            id,
            prerequisites: prerequisites,
            requiredReadiness: requiredReadiness
        )
        self.strand = strand
        self.title = title
        self.developmentalOrder = developmentalOrder
        self.representations = representations
        self.responseModes = responseModes
        self.mechanicIDs = mechanicIDs
        self.isStretch = isStretch
    }
}

public enum PuzzleSkills {
    public static let visualSequenceMemory = SkillID(rawValue: "puzzle.workingMemory.visualSequence")
    public static let responseInhibition = SkillID(rawValue: "puzzle.inhibition.stopAndGo")
    public static let visualPatternContinue = SkillID(rawValue: "puzzle.patterns.continueAB")
    public static let patternRuleTransfer = SkillID(rawValue: "puzzle.patterns.transferRule")
    public static let singleRuleSort = SkillID(rawValue: "puzzle.sorting.singleRule")
    public static let ruleSwitching = SkillID(rawValue: "puzzle.flexibility.switchRule")
    public static let changedRuleSort = SkillID(rawValue: "puzzle.sorting.changedRule")
    public static let spatialOrientation = SkillID(rawValue: "puzzle.spatial.orientation")
    public static let mentalRotation = SkillID(rawValue: "puzzle.spatial.mentalRotation")
    public static let pathPlanning = SkillID(rawValue: "puzzle.planning.path")
    public static let actionSequencing = SkillID(rawValue: "puzzle.sequencing.actions")
    public static let debugSingleStep = SkillID(rawValue: "puzzle.debugging.singleStep")
    public static let debugSequence = SkillID(rawValue: "puzzle.debugging.sequence")
}

public enum PuzzleSkillCatalog {
    public static let descriptors: [PuzzleSkillDescriptor] = [
        .init(
            id: PuzzleSkills.visualSequenceMemory,
            strand: .workingMemory,
            title: "Remember a Short Visual Sequence",
            developmentalOrder: 1,
            representations: [.rune, .object],
            responseModes: [.directTouch, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.memoryBridge, PuzzlePalaceMechanicID.runeGate]
        ),
        .init(
            id: PuzzleSkills.responseInhibition,
            strand: .inhibitoryControl,
            title: "Wait for the Correct Go Signal",
            developmentalOrder: 2,
            representations: [.object],
            responseModes: [.holdAndRelease, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.stopGoOrbs]
        ),
        .init(
            id: PuzzleSkills.visualPatternContinue,
            strand: .patterns,
            title: "Continue an Alternating Visual Pattern",
            developmentalOrder: 3,
            representations: [.rune, .object],
            responseModes: [.directTouch, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.runeGate]
        ),
        .init(
            id: PuzzleSkills.singleRuleSort,
            strand: .sorting,
            title: "Sort Objects by One Visible Rule",
            developmentalOrder: 4,
            representations: [.object],
            responseModes: [.arrange, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.sortingPedestal]
        ),
        .init(
            id: PuzzleSkills.patternRuleTransfer,
            strand: .patterns,
            title: "Apply a Pattern Rule to New Symbols",
            developmentalOrder: 5,
            prerequisites: [PuzzleSkills.visualPatternContinue],
            representations: [.rune, .object],
            responseModes: [.directTouch, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.runeGate, PuzzlePalaceMechanicID.memoryBridge]
        ),
        .init(
            id: PuzzleSkills.ruleSwitching,
            strand: .cognitiveFlexibility,
            title: "Switch to a New Rule When the World Changes",
            developmentalOrder: 6,
            prerequisites: [PuzzleSkills.responseInhibition],
            representations: [.object],
            responseModes: [.switchRule, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.stopGoOrbs, PuzzlePalaceMechanicID.sortingPedestal]
        ),
        .init(
            id: PuzzleSkills.changedRuleSort,
            strand: .sorting,
            title: "Re-sort the Same Objects Using a Different Rule",
            developmentalOrder: 7,
            prerequisites: [PuzzleSkills.singleRuleSort, PuzzleSkills.ruleSwitching],
            representations: [.object],
            responseModes: [.switchRule, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.sortingPedestal]
        ),
        .init(
            id: PuzzleSkills.spatialOrientation,
            strand: .spatialReasoning,
            title: "Track Direction and Position",
            developmentalOrder: 8,
            representations: [.path, .rotation],
            responseModes: [.route, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.mirrorHall, PuzzlePalaceMechanicID.pathTiles]
        ),
        .init(
            id: PuzzleSkills.mentalRotation,
            strand: .spatialReasoning,
            title: "Recognize a Shape After Rotation",
            developmentalOrder: 9,
            prerequisites: [PuzzleSkills.spatialOrientation],
            representations: [.rotation],
            responseModes: [.directTouch, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.mirrorHall],
            isStretch: true
        ),
        .init(
            id: PuzzleSkills.actionSequencing,
            strand: .sequencing,
            title: "Put Actions in a Useful Order",
            developmentalOrder: 10,
            prerequisites: [PuzzleSkills.visualSequenceMemory],
            representations: [.command, .path],
            responseModes: [.arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.commandGears]
        ),
        .init(
            id: PuzzleSkills.pathPlanning,
            strand: .planning,
            title: "Plan a Route Before Moving",
            developmentalOrder: 11,
            prerequisites: [PuzzleSkills.spatialOrientation, PuzzleSkills.visualSequenceMemory],
            representations: [.path, .command],
            responseModes: [.route, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.pathTiles, PuzzlePalaceMechanicID.commandGears]
        ),
        .init(
            id: PuzzleSkills.debugSingleStep,
            strand: .debugging,
            title: "Find One Broken Step in a Plan",
            developmentalOrder: 12,
            prerequisites: [PuzzleSkills.actionSequencing],
            representations: [.command, .path],
            responseModes: [.debug, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.bugLantern]
        ),
        .init(
            id: PuzzleSkills.debugSequence,
            strand: .debugging,
            title: "Repair a Multi-Step Plan",
            developmentalOrder: 13,
            prerequisites: [PuzzleSkills.debugSingleStep, PuzzleSkills.pathPlanning],
            representations: [.command, .path],
            responseModes: [.debug, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.bugLantern, PuzzlePalaceMechanicID.commandGears],
            isStretch: true
        )
    ]

    public static let stretchSkills: [PuzzleSkillDescriptor] = descriptors.filter(\.isStretch)

    public static func descriptor(for id: SkillID) -> PuzzleSkillDescriptor? {
        descriptors.first { $0.id == id }
    }

    public static func graph() throws -> SkillGraph {
        try SkillGraph(descriptors.map(\.definition))
    }
}
