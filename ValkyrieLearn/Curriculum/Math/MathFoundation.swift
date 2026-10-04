import Foundation

public enum MathSkills {
    public static let quantity = SkillID(rawValue: "math.quantityRecognition")
    public static let counting = SkillID(rawValue: "math.countingCardinality")
    public static let subitizing = SkillID(rawValue: "math.subitizing")
    public static let compare = SkillID(rawValue: "math.compareQuantities")
    public static let addition = SkillID(rawValue: "math.additionObjects")
    public static let subtraction = SkillID(rawValue: "math.subtractionObjects")
    public static let bonds5 = SkillID(rawValue: "math.numberBonds5")
    public static let bonds10 = SkillID(rawValue: "math.numberBonds10")
    public static let missing = SkillID(rawValue: "math.missingAddends")
    public static func graph() throws -> SkillGraph {
        try SkillGraph([
            SkillDefinition(quantity),
            SkillDefinition(counting, prerequisites: [quantity]),
            SkillDefinition(subitizing, prerequisites: [quantity]),
            SkillDefinition(compare, prerequisites: [counting]),
            SkillDefinition(addition, prerequisites: [counting]),
            SkillDefinition(subtraction, prerequisites: [counting, addition]),
            SkillDefinition(bonds5, prerequisites: [addition, subitizing]),
            SkillDefinition(bonds10, prerequisites: [bonds5]),
            SkillDefinition(missing, prerequisites: [addition, bonds10])
        ])
    }
}

// Small authored foundation catalog, not a generated question bank or standards claim.
public enum MathFoundation {
    public static let encounters: [LearningEncounter] = {
        var result: [LearningEncounter] = []
        for (skill, prefix) in [(MathSkills.quantity, "quantity"), (MathSkills.counting, "count")] {
            for total in [7, 5, 8, 6] {
                result.append(LearningEncounter(id: "\(prefix)-\(total)", skillID: skill,
                    operation: .counting, initialQuantity: 0, targetQuantity: total,
                    prompt: "Put \(total) crystals into Pip's cart."))
            }
        }
        for (start, add) in [(4, 3), (3, 2), (5, 4)] {
            result.append(LearningEncounter(id: "add-\(start)-\(add)", skillID: MathSkills.addition,
                operation: .addition, initialQuantity: start, targetQuantity: start + add,
                prompt: "There are \(start) crystals in the cart. Add \(add) more."))
        }
        for (start, total) in [(6, 10), (7, 10), (3, 8)] {
            result.append(LearningEncounter(id: "missing-\(start)-\(total)", skillID: MathSkills.missing,
                operation: .missingAddend, initialQuantity: start, targetQuantity: total,
                prompt: "The machine needs \(total) crystals. It already has \(start)."))
        }
        return result
    }()
    // Engineering workshop previews are explicitly unscored and bypass no readiness gates.
    public static let workshopExamples = [encounters[0], encounters[8], encounters[11]]
}
