import SwiftUI
import LearningCore

@MainActor struct AdventureSettingsView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Grown-up view") {
                    NavigationLink {
                        ParentMathDashboardView(state: state)
                    } label: {
                        Label("Math progress", systemImage: "chart.bar.doc.horizontal")
                    }

                    Text("See strengths, skills in progress, review needs, and what the adaptive system thinks is ready next.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Adventure") {
                    Toggle("Gentle sounds", isOn: $state.soundEnabled)
                    Toggle("Reduced motion", isOn: $state.reducedMotion)
                }

                Section("Build notes") {
                    Text("The illustrated Story Tree and Math Castle use the v3.31 art direction. Workshop examples remain unscored.")
                }

                if let error = state.saveError {
                    Section("Saving") {
                        Text(error).foregroundStyle(.red)
                        Button("Retry saving") { state.retrySave() }
                    }
                }
            }
            .navigationTitle("Adventure settings")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

@MainActor private struct ParentMathDashboardView: View {
    @ObservedObject var state: AppState

    private var summary: ParentMathSummary { state.parentMathSummary() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                overviewCard

                if let session = summary.recentSession {
                    recentSessionCard(session)
                }

                skillSection(
                    title: "Strengths",
                    subtitle: "Secure or mastered through repeated learning evidence.",
                    systemImage: "sparkles",
                    skills: summary.strengths,
                    empty: "Secure skills will appear here after repeated independent evidence."
                )

                skillSection(
                    title: "Developing now",
                    subtitle: "Skills the adaptive system is actively building.",
                    systemImage: "hammer",
                    skills: summary.developing,
                    empty: "No skills are currently marked Learning or Developing."
                )

                skillSection(
                    title: "Review needed",
                    subtitle: "Previously strong skills due for retrieval practice.",
                    systemImage: "arrow.clockwise",
                    skills: summary.reviewNeeds,
                    empty: "Nothing is due for spaced review right now."
                )

                skillSection(
                    title: "Ready next",
                    subtitle: "Prerequisite-safe new skills, not an age or grade ceiling.",
                    systemImage: "arrow.forward.circle",
                    skills: Array(summary.readyNext.prefix(6)),
                    empty: "The system is still gathering enough readiness evidence."
                )

                methodologyCard
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Math progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Adaptive Math overview", systemImage: "function")
                .font(.title2.bold())

            HStack(alignment: .top, spacing: 12) {
                statusPill(
                    state.placementComplete ? "Placement complete" : "Placement in progress",
                    systemImage: state.placementComplete ? "checkmark.circle.fill" : "circle.dotted"
                )

                if state.hasStoryReward(.moonLantern) {
                    statusPill("Moon Lantern earned", systemImage: "moon.stars.fill")
                }
            }

            Text(
                state.placementComplete
                    ? "Hidden placement is complete. Placement can mark prerequisites as ready, but it never labels a skill Secure or Mastered by itself."
                    : "Math Castle is quietly estimating a useful starting point without showing a test screen."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if summary.placementReadyCount > 0 {
                Text("Provisional placement readiness is used only to skip unnecessary prerequisite work and choose appropriate challenges.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .parentCard()
    }

    private func recentSessionCard(_ session: ParentMathRecentSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent learning", systemImage: "clock.fill")
                .font(.title3.bold())

            Text(session.endedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(session.skills.prefix(4)), id: \.id) { skill in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(skill.title).font(.body.weight(.medium))
                        Text(strandLabel(skill.strand))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    stateBadge(skill.state)
                }
            }

            Divider()

            Label(
                session.usedPipSupport
                    ? "Pip support was used during this learning block."
                    : "Recorded successes in this block were independent.",
                systemImage: session.usedPipSupport ? "person.2.fill" : "figure.child"
            )
            .font(.footnote)

            if session.includedReasoningOrStory {
                Label("This block included story/application or reasoning work.", systemImage: "brain.head.profile")
                    .font(.footnote)
            }
        }
        .parentCard()
    }

    private func skillSection(
        title: String,
        subtitle: String,
        systemImage: String,
        skills: [ParentMathSkillSnapshot],
        empty: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage).font(.title3.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)

            if skills.isEmpty {
                Text(empty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(skills, id: \.id) { skill in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.title).font(.body.weight(.medium))
                            Text(strandLabel(skill.strand))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        stateBadge(skill.state)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .parentCard()
    }

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("How to read this", systemImage: "info.circle")
                .font(.headline)
            Text("Secure and Mastered require repeated learning evidence. A single correct answer does not create mastery.")
            Text("Ready next means prerequisites are currently satisfied. It does not mean the child must work on that skill immediately.")
            Text("The dashboard reports skill meaning and learning signals rather than raw question totals.")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .parentCard()
    }

    private func statusPill(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }

    private func stateBadge(_ state: SkillState) -> some View {
        Text(stateLabel(state))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.thinMaterial, in: Capsule())
    }

    private func stateLabel(_ state: SkillState) -> String {
        switch state {
        case .new: return "New"
        case .learning: return "Learning"
        case .developing: return "Developing"
        case .secure: return "Secure"
        case .reviewDue: return "Review due"
        case .mastered: return "Mastered"
        }
    }

    private func strandLabel(_ strand: MathStrand) -> String {
        switch strand {
        case .numberSense: return "Number sense"
        case .numberComposition: return "Number composition"
        case .addition: return "Addition"
        case .subtraction: return "Subtraction"
        case .placeValue: return "Place value"
        case .patternsAlgebra: return "Patterns & early algebra"
        case .geometrySpatial: return "Geometry & spatial reasoning"
        case .measurementDataTimeMoney: return "Measurement, data, time & money"
        case .reasoning: return "Mathematical reasoning"
        case .stretch: return "Readiness-based stretch"
        }
    }
}

private extension View {
    func parentCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 18)
            )
    }
}
