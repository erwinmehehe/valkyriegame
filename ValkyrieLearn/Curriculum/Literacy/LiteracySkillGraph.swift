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
    public static let seedBlendPath = "wordGarden.seedBlendPath"
    public static let wordBloom = "wordGarden.wordBloom"
    public static let storyLantern = "wordGarden.storyLantern"
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

        // Connect sound to print.
        .init(
            id: LiteracySkills.uppercaseLetterNames,
            strand: .alphabeticPrinciple,
            title: "Recognize Uppercase Letter Names",
            developmentalOrder: 11,
            representations: [.letter, .picture],
            responseModes: [.directTouch, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.letterStones]
        ),
        .init(
            id: LiteracySkills.lowercaseLetterNames,
            strand: .alphabeticPrinciple,
            title: "Recognize Lowercase Letter Names",
            developmentalOrder: 12,
            prerequisites: [LiteracySkills.uppercaseLetterNames],
            representations: [.letter, .picture],
            responseModes: [.directTouch, .pictureChoice],
            mechanicIDs: [WordGardenMechanicID.letterStones]
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
