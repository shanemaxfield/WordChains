import SwiftUI

struct ContentView: View {
    @StateObject var freeRoamState = GameState()
    @State private var dummyText = ""
    @FocusState private var dummyFocus: Bool
    @State private var showWelcomeMessage = true
    @State private var neverShowAgain = false

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
            
            // Welcome Message Overlay
            if showWelcomeMessage {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color("C_PureWhite").opacity(0.8))

                        Text("Word Chains")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Color("C_PureWhite"))
                    }

                    VStack(spacing: 8) {
                        Text("Start with the first word.")
                        Text("Change one letter at a time.")
                        Text("Reach the target word in the fewest steps.")
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color("C_PureWhite").opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                    Toggle(isOn: $neverShowAgain) {
                        Text("Don't show this again")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color("C_PureWhite").opacity(0.85))
                    }
                    .toggleStyle(iOSCheckboxToggleStyle())
                    .padding(.top, 8)

                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showWelcomeMessage = false
                            if neverShowAgain {
                                UserDefaults.standard.set(true, forKey: "hideWelcomeMessage")
                            }
                        }
                    }) {
                        Text("Start Playing")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color("C_PureWhite"))
                            .padding(.vertical, 14)
                            .padding(.horizontal, 48)
                            .background(
                                Capsule().fill(Color("C_WarmTeal"))
                            )
                            .shadow(color: Color("C_WarmTeal").opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color("C_Charcoal").opacity(0.96))
                )
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
            }


        }
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
        }
    }
    struct iOSCheckboxToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button(action: {
                configuration.isOn.toggle()
            }) {
                HStack {
                    Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("C_WarmTeal"))
                    configuration.label
                }
            }
            .buttonStyle(PlainButtonStyle())
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


