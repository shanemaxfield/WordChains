import SwiftUI

struct ContentView: View {
    @StateObject var freeRoamState = GameState()
    @State private var dummyText = ""
    @FocusState private var dummyFocus: Bool
    @State private var onboardingStep: Int = 0

    var body: some View {
        ZStack {
            NavigationView {
                PuzzleOfTheDayView()
                    .environmentObject(freeRoamState)
                    .navigationBarHidden(true)
            }

            // Hidden TextField to pre-warm keyboard/input system
            TextField("", text: $dummyText)
                .focused($dummyFocus)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        .overlay(
            OnboardingOverlay(
                isShowing: $freeRoamState.showOnboarding,
                currentStep: $onboardingStep,
                steps: OnboardingData.tutorialSteps,
                onComplete: {
                    freeRoamState.completeOnboarding()
                }
            )
        )
        .onAppear {
            print("🧪 .onAppear triggered — loading data")
            WordDataManager.shared.loadData()

            // 👉 Input your 6 anchor words here (results in 5 chains)
            let anchorWords = ["NUN", "ABS", "TOW", "ARK"]
            let logic = WordChainGameLogic(wordLength: 3)

            generateMultiChainPath(words: anchorWords, logic: logic)

            // Pre-warm the keyboard/input system
            dummyFocus = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dummyFocus = false
            }
            
            // Check if we should show onboarding
            freeRoamState.checkAndShowOnboarding()
        }
    }

    /// Generates and prints shortest chains between consecutive anchor word pairs
    func generateMultiChainPath(words: [String], logic: WordChainGameLogic) {
        guard words.count >= 2 else {
            print("❗️ Need at least 2 words")
            return
        }

        for i in 0..<(words.count - 1) {
            let start = words[i]
            let end = words[i + 1]

            if logic.isValidWord(start), logic.isValidWord(end) {
                let chain = logic.findShortestChain(from: start, to: end)
                if chain.isEmpty {
                    print("❌ No chain found from \(start) to \(end)")
                } else {
                    print("🔗 \(start) → \(end): \(chain.joined(separator: " → "))")
                }
            } else {
                print("🚫 Invalid word(s): \(start) or \(end) not in word list")
            }
        }
    }
}


