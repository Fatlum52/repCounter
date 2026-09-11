import Testing
@testable import repCounter

@MainActor
struct ExploreRankingTests {

    private func exercise(_ name: String) -> ExerciseDTO {
        ExerciseDTO(
            exerciseId: name, name: name, imageUrl: nil, videoUrl: nil,
            targetMuscles: [], bodyParts: [], equipments: [], secondaryMuscles: [], instructions: nil
        )
    }

    private func ranked(_ names: [String], for query: String) -> [String] {
        ExploreModel.rankedByRelevance(names.map(exercise), query: query).map(\.name)
    }

    // The order the API actually returned for "bench press".
    @Test func exactMatchBeatsApiOrder() {
        let apiOrder = [
            "Dumbbell Incline One Arm Hammer Press", "Diamond Press", "Cross Body Hammer Curl",
            "Seated Shoulder Flexor Depresor Retractor Stretch", "Triceps Press ", "Arnold Press",
            "Bench dip on floor", "Seated Shoulder Press", "Palms In Incline Bench Press",
            "Dumbbell Clean and Press", "Bench Press", "Dumbbell Decline One Arm Hammer Press"
        ]
        let result = ranked(apiOrder, for: "bench press")

        #expect(Array(result.prefix(2)) == ["Bench Press", "Palms In Incline Bench Press"])
        #expect(Set(result.suffix(2)) == ["Cross Body Hammer Curl", "Seated Shoulder Flexor Depresor Retractor Stretch"])
    }

    @Test func ignoresCasePunctuationAndWhitespace() {
        #expect(ranked(["Commando Pull-up", "Pull-up with Bent Knee", "Pull up"], for: "  PULL-UP ")
                == ["Pull up", "Pull-up with Bent Knee", "Commando Pull-up"])
    }

    @Test func tiesKeepShorterNamesThenApiOrder() {
        #expect(ranked(["Seated Shoulder Press", "Arnold Press", "Diamond Press"], for: "press")
                == ["Arnold Press", "Diamond Press", "Seated Shoulder Press"])
    }
}
