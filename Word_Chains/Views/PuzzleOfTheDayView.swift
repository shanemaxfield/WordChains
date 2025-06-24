import SwiftUI

// Helper struct for composite key
struct ChangesKey: Hashable, Codable {
    let wordLength: Int
    let chainIndex: Int
}

struct PuzzleOfTheDayView: View {
    @State private var wordLength: Int = 4
    @State private var userWordMap: [Int: String] = [:]
    @State private var puzzleCompletedMap: [Int: Bool] = [:]
    @State private var changesMadeMap: [ChangesKey: Int] = [:] // Use struct key
    @State private var currentChainIndexMap: [Int: Int] = [:]
    @AppStorage("potd_userWordMap") private var userWordMapData: Data = Data()
    @AppStorage("potd_puzzleCompletedMap") private var puzzleCompletedMapData: Data = Data()
    @AppStorage("potd_currentChainIndexMap") private var currentChainIndexMapData: Data = Data()
    @AppStorage("potd_changesMadeMap") private var changesMadeMapData: Data = Data()
    @AppStorage("potd_hintActiveByLength") private var hintActiveByLengthData: Data = Data()
    @AppStorage("potd_hintDistanceByLength") private var hintDistanceByLengthData: Data = Data()
    @State private var chainMap: [Int: [String]] = [:]
    @FocusState private var focusedIndex: Int?
    @State private var resetTrigger: Bool = false
    @EnvironmentObject var freeRoamState: GameState
    @State private var gameLogicsByLength: [Int: WordChainGameLogic] = [:]
    @State private var showSuccess: Bool = false
    @State private var externalInvalidTriggers: [Int: Bool] = [:]
    @State private var showInvalidMessage: Bool = false
    @State private var externalInvalidLetters: [Int: String?] = [:]
    @State private var isCelebrating: Bool = false
    @State private var celebrationStartTime: Date = Date()
    @State private var showCelebrationCard: Bool = false
    @State private var showMinimumChain: Bool = false
    @State private var navigateToFreeRoam: Bool = false
    @State private var allChainsForToday: [[String]] = []
    @State private var isChainCelebrating: Bool = false
    @State private var targetTextAnimate: Bool = false
    @State private var targetLetterBounces: [Bool] = []
    @State private var hintActiveByLength: [Int: Bool] = [:]
    @State private var hintDistanceByLength: [Int: Int] = [:]
    @State private var shouldAnimateTarget: Bool = false
    // Store closures to trigger invalid letter animation for each tile
    private var tileInvalidTriggers: [Int: (String) -> Void] {
        (0..<wordLength).reduce(into: [Int: (String) -> Void]()) { dict, idx in
            dict[idx] = { _ in }
        }
    }

    let lengthOptions = [3, 4, 5]
    let lengthLabels = [3: "3-Letter", 4: "4-Letter", 5: "5-Letter"]

    var currentChainIndex: Int {
        get { currentChainIndexMap[wordLength] ?? 0 }
        set { currentChainIndexMap[wordLength] = newValue }
    }
    var userWord: String { userWordMap[wordLength] ?? "" }
    var puzzleCompleted: Bool { puzzleCompletedMap[wordLength] ?? false }
    var gameLogic: WordChainGameLogic {
        if let logic = gameLogicsByLength[wordLength] { return logic }
        let logic = WordChainGameLogic(wordLength: wordLength)
        gameLogicsByLength[wordLength] = logic
        return logic
    }

    var totalChangesMade: Int {
        changesMadeMap.filter { $0.key.wordLength == wordLength }.map { $0.value }.reduce(0, +)
    }
    var totalMinimumPossible: Int {
        allChainsForToday.map { max($0.count - 1, 0) }.reduce(0, +)
    }

    var isPuzzleCompleted: Bool {
        // All chains for the current word length must be completed
        guard allChainsForToday.count > 0 else { return false }
        // Check if the user has completed the last chain
        return puzzleCompletedMap[wordLength] == true && currentChainIndex == allChainsForToday.count - 1
    }

    var chain: [String] {
        guard allChainsForToday.indices.contains(currentChainIndex) else { return [] }
        return allChainsForToday[currentChainIndex]
    }

    private var confettiOverlay: some View {
        Group {
            if isCelebrating {
                CelebrationConfettiView().transition(.opacity)
            }
        }
    }

    private var backgroundOverlay: some View {
        Group {
            if let paper = UIImage(named: "PaperTexture") {
                Image(uiImage: paper)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.12)
                    .ignoresSafeArea()
            } else {
                LinearGradient(gradient: Gradient(colors: [Color("SandstoneBeige"), Color("SoftSand").opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
    }

    private var navigationOverlay: some View {
        NavigationLink(destination: FreeRoamView().environmentObject(freeRoamState), isActive: $navigateToFreeRoam) { EmptyView() }
    }

    private var mainContent: some View {
        VStack(spacing: 6) {
            Text("Puzzle of the Day")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(Color("MutedNavy"))
                .padding(.top, 12)
                .padding(.bottom, 24)
            // Capsule Length Selector
            HStack(spacing: 8) {
                ForEach(lengthOptions, id: \.self) { option in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            wordLength = option
                            if gameLogicsByLength[option] == nil {
                                gameLogicsByLength[option] = WordChainGameLogic(wordLength: option)
                            }
                            loadAllChainsForToday()
                        }
                    }) {
                        Text(lengthLabels[option] ?? "")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(wordLength == option ? .white : Color("MutedNavy"))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 22)
                            .background(
                                Capsule()
                                    .fill(wordLength == option ? Color("SlateBlueGrey") : Color("SoftSand"))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(wordLength == option ? Color("SlateBlueGrey") : Color("AshGray"), lineWidth: 1.2)
                            )
                            .shadow(color: wordLength == option ? Color("SlateBlueGrey").opacity(0.15) : .clear, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            if !chain.isEmpty {
                GameCardView(
                    tilesCount: chain.first?.count ?? 0,
                    makeTile: { index in
                        AnyView(
                            EditableLetterTile(
                                index: index,
                                wordLength: wordLength,
                                userWord: Binding(
                                    get: { userWord },
                                    set: { newWord in
                                        let oldWord = userWord
                                        var map = userWordMap
                                        map[wordLength] = newWord
                                        userWordMap = map
                                        if oldWord != newWord {
                                            var changesMap = changesMadeMap
                                            changesMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] = (changesMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] ?? 0) + 1
                                            changesMadeMap = changesMap
                                        }
                                        validateWord()
                                        if hintActiveByLength[wordLength] == true {
                                            let logic = gameLogicsByLength[wordLength] ?? WordChainGameLogic(wordLength: wordLength)
                                            let distance = logic.getDistanceToTarget(from: newWord)
                                            hintDistanceByLength[wordLength] = distance
                                            gameLogicsByLength[wordLength] = logic
                                        }
                                    }
                                ),
                                focusedIndex: $focusedIndex,
                                gameLogic: gameLogic,
                                onInvalidEntry: {
                                    showInvalidMessage = true
                                },
                                externalInvalidTrigger: Binding(
                                    get: { externalInvalidTriggers[index] ?? false },
                                    set: { externalInvalidTriggers[index] = $0 }
                                ),
                                externalInvalidLetter: Binding(
                                    get: { externalInvalidLetters[index] ?? nil },
                                    set: { externalInvalidLetters[index] = $0 }
                                )
                            )
                            .modifier(CelebrationTileEffect(
                                isActive: isChainCelebrating,
                                index: index,
                                startTime: celebrationStartTime
                            ))
                        )
                    },
                    targetWord: chain.last ?? "----",
                    showReset: true,
                    onReset: {
                        let start = chain.first ?? ""
                            var map = userWordMap
                            map[wordLength] = start
                            userWordMap = map
                        focusedIndex = 0
                        // Do NOT clear hint state on reset
                    },
                    showFreeRoam: true,
                    onFreeRoam: {
                        navigateToFreeRoam = true
                    },
                    cardColor: Color("C_PureWhite"),
                    puzzleCompleted: isPuzzleCompleted,
                    invalidMessage: showInvalidMessage ? "Not in word list" : nil,
                    showInvalidMessage: showInvalidMessage,
                    showSuccess: false,
                    successMessage: nil,
                    onSuccessAction: nil,
                    successActionLabel: nil,
                    minimumChanges: max(chain.count - 1, 0),
                    onHint: {
                        let logic = gameLogicsByLength[wordLength] ?? WordChainGameLogic(wordLength: wordLength)
                        let currentChain = allChainsForToday.indices.contains(currentChainIndex) ? allChainsForToday[currentChainIndex] : []
                        let target = currentChain.last ?? ""
                        logic.precomputeDistancesToTarget(target)
                        let word = userWordMap[wordLength] ?? ""
                        let distance = logic.getDistanceToTarget(from: word)
                        hintActiveByLength[wordLength] = true
                        hintDistanceByLength[wordLength] = distance
                        gameLogicsByLength[wordLength] = logic
                    },
                    currentDistance: (hintDistanceByLength[wordLength] ?? -1) == -1 ? nil : hintDistanceByLength[wordLength],
                    isHintActive: hintActiveByLength[wordLength] ?? false,
                    bottomRightButton: {
                        AnyView(
                            Button(action: {
                                navigateToFreeRoam = true
                            }) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        )
                    },
                    shouldAnimateTarget: shouldAnimateTarget
                )
                .frame(height: 270)
                .padding(.top, 32)
                LetterKeyboard(
                    onLetterTap: { letter in
                        if let currentIndex = focusedIndex {
                            var wordArray = Array(userWord)
                            if currentIndex < wordArray.count {
                                let previousLetter = wordArray[currentIndex]
                                wordArray[currentIndex] = letter.first!
                                let newWord = String(wordArray)
                                if gameLogic.isValidWord(newWord) == true {
                                    withAnimation {
                                        var map = userWordMap
                                        map[wordLength] = newWord
                                        userWordMap = map
                                    }
                                    // Increment changes for the current chain and word length
                                    var changesMap = changesMadeMap
                                    changesMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] = (changesMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] ?? 0) + 1
                                    changesMadeMap = changesMap
                                    validateWord()
                                } else {
                                    // Show invalid state
                                    externalInvalidLetters[currentIndex] = letter
                                    withAnimation {
                                        showInvalidMessage = true
                                    }
                                    // Clear the invalid letter and revert to previous letter after animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        externalInvalidLetters[currentIndex] = nil
                                        showInvalidMessage = false
                                        // Revert to previous letter
                                        var revertedArray = Array(userWord)
                                        revertedArray[currentIndex] = previousLetter
                                        var map = userWordMap
                                        map[wordLength] = String(revertedArray)
                                        userWordMap = map
                                    }
                                }
                            }
                        }
                    },
                    onDelete: {
                        if let currentIndex = focusedIndex {
                            var wordArray = Array(userWord)
                            if currentIndex < wordArray.count {
                                wordArray[currentIndex] = " "
                                withAnimation {
                                    var map = userWordMap
                                    map[wordLength] = String(wordArray)
                                    userWordMap = map
                                }
                                // Increment changes for the current chain and word length
                                var changesMap = changesMadeMap
                                changesMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] = (changesMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] ?? 0) + 1
                                changesMadeMap = changesMap
                            }
                        }
                    }
                )
                .padding(.top, 48)
                .padding(.horizontal, 8)
            } else {
                Text("Loading...")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(Color("SlateBlueGrey"))
                    .padding(.vertical, 40)
            }
        }
        .padding(.horizontal, 12)
    }

    var body: some View {
        ZStack {
            Color("SandstoneBeige").ignoresSafeArea()
            backgroundOverlay
            CelebrationPulseOverlay(isActive: isCelebrating)
            mainContent
            confettiOverlay
            // Celebration card overlay (single instance)
            if showCelebrationCard || showMinimumChain {
                CelebrationCardView(
                    onRetry: {
                        setCurrentChainIndex(allChainsForToday.count > 0 ? 0 : 0)
                        let firstChain = allChainsForToday.first ?? []
                        let start = firstChain.first ?? ""
                        var map = userWordMap
                        map[wordLength] = start
                        userWordMap = map
                        var completedMap = puzzleCompletedMap
                        completedMap[wordLength] = false
                        puzzleCompletedMap = completedMap
                        var changesMap = changesMadeMap
                        for idx in allChainsForToday.indices {
                            changesMap[ChangesKey(wordLength: wordLength, chainIndex: idx)] = 0
                        }
                        changesMadeMap = changesMap
                        showMinimumChain = false
                        showCelebrationCard = false
                    },
                    onShowMinimum: {
                        if showMinimumChain {
                            // Back arrow: return to celebration card
                            showMinimumChain = false
                            showCelebrationCard = true
                        } else {
                            // Show minimum chain overlay
                            showMinimumChain = true
                            showCelebrationCard = false
                        }
                    },
                    onNext: nil,
                    onFreeRoam: {
                        navigateToFreeRoam = true
                        showCelebrationCard = false
                        showMinimumChain = false
                    },
                    changesMade: totalChangesMade,
                    minimumChanges: totalMinimumPossible,
                    showFreeRoamButton: !showMinimumChain,
                    showMinimumChain: showMinimumChain,
                    minimumChain: [],
                    minimumChainGroups: allChainsForToday,
                    onWordLengthChange: { newLength in
                        wordLength = newLength
                        showCelebrationCard = false
                        showMinimumChain = false
                    },
                    currentWordLength: wordLength
                )
                .zIndex(101)
            }
            navigationOverlay
        }
        .animation(.spring(response: 1.2, dampingFraction: 0.85), value: showCelebrationCard)
        .onAppear {
            // Restore all state from storage
            userWordMap = (try? JSONDecoder().decode([Int: String].self, from: userWordMapData)) ?? [:]
            puzzleCompletedMap = (try? JSONDecoder().decode([Int: Bool].self, from: puzzleCompletedMapData)) ?? [:]
            changesMadeMap = (try? JSONDecoder().decode([ChangesKey: Int].self, from: changesMadeMapData)) ?? [:]
            currentChainIndexMap = (try? JSONDecoder().decode([Int: Int].self, from: currentChainIndexMapData)) ?? [:]
            loadAllChainsForToday()
            if puzzleCompletedMap[wordLength] == true {
                setCurrentChainIndex(allChainsForToday.count > 0 ? allChainsForToday.count - 1 : 0)
                showCelebrationCard = true
            } else {
                showCelebrationCard = false
            }
            // Set focusedIndex to 0 when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedIndex = 0
            }
            hintActiveByLength = (try? JSONDecoder().decode([Int: Bool].self, from: hintActiveByLengthData)) ?? [:]
            hintDistanceByLength = (try? JSONDecoder().decode([Int: Int].self, from: hintDistanceByLengthData)) ?? [:]
            // Recompute hint distances for all active hints
            for length in [3, 4, 5] {
                if hintActiveByLength[length] == true {
                    let logic = gameLogicsByLength[length] ?? WordChainGameLogic(wordLength: length)
                    let chainIdx = currentChainIndexMap[length] ?? 0
                    let allChains = PuzzleChainLoader.shared.getDailyChains(for: Date(), wordLength: length)
                    let chain = allChains.indices.contains(chainIdx) ? allChains[chainIdx] : []
                    let target = chain.last ?? ""
                    logic.precomputeDistancesToTarget(target)
                    let word = userWordMap[length] ?? ""
                    let distance = logic.getDistanceToTarget(from: word)
                    hintDistanceByLength[length] = distance
                    gameLogicsByLength[length] = logic
                }
            }
        }
        .onChange(of: userWordMap) { newValue in
            userWordMapData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        .onChange(of: puzzleCompletedMap) { newValue in
            puzzleCompletedMapData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        .onChange(of: changesMadeMap) { newValue in
            changesMadeMapData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        .onChange(of: currentChainIndex) { newValue in
            currentChainIndexMap[wordLength] = newValue
            currentChainIndexMapData = (try? JSONEncoder().encode(currentChainIndexMap)) ?? Data()
            // Initialize changesMadeMap for the new chain
            if changesMadeMap[ChangesKey(wordLength: wordLength, chainIndex: newValue)] == nil {
                changesMadeMap[ChangesKey(wordLength: wordLength, chainIndex: newValue)] = 0
            }
        }
        .onChange(of: wordLength) { oldValue in
            // Restore all state from storage for new word length
            let previousLength = oldValue
            userWordMap = (try? JSONDecoder().decode([Int: String].self, from: userWordMapData)) ?? [:]
            puzzleCompletedMap = (try? JSONDecoder().decode([Int: Bool].self, from: puzzleCompletedMapData)) ?? [:]
            changesMadeMap = (try? JSONDecoder().decode([ChangesKey: Int].self, from: changesMadeMapData)) ?? [:]
            currentChainIndexMap = (try? JSONDecoder().decode([Int: Int].self, from: currentChainIndexMapData)) ?? [:]
            loadAllChainsForToday()
            if puzzleCompletedMap[wordLength] == true {
                setCurrentChainIndex(allChainsForToday.count > 0 ? allChainsForToday.count - 1 : 0)
                showCelebrationCard = true
            } else {
                showCelebrationCard = false
            }
            focusedIndex = 0
        }
        .onChange(of: puzzleCompletedMap[wordLength] ?? false) { completed in
            handlePuzzleCompletionChange(completed)
        }
        .onChange(of: hintActiveByLength) { newValue in
            hintActiveByLengthData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        .onChange(of: hintDistanceByLength) { newValue in
            hintDistanceByLengthData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        .onChange(of: navigateToFreeRoam) { isNavigating in
            if !isNavigating {
                // When returning from Free Roam, restore the keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusedIndex = 0
                }
            }
        }
    }

    private func handlePuzzleCompletionChange(_ completed: Bool) {
        if !completed {
            showSuccess = false
            isCelebrating = false
            showCelebrationCard = false
            showMinimumChain = false
            focusedIndex = 0
            isChainCelebrating = false
        } else {
            if currentChainIndex + 1 < allChainsForToday.count {
                advanceToNextChain()
            } else {
                showFinalCelebration()
            }
        }
    }

    private func advanceToNextChain() {
        isChainCelebrating = true
        shouldAnimateTarget = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            advanceChainAfterDelay()
        }
    }

    private func advanceChainAfterDelay() {
        isChainCelebrating = false
        setCurrentChainIndex(currentChainIndex + 1)
        // Set up for next chain
        let nextChain = allChainsForToday[currentChainIndex]
        var map = userWordMap
        map[wordLength] = nextChain.first ?? ""
        userWordMap = map
        // Always set puzzle as not completed on chain switch
        var completedMap = puzzleCompletedMap
        completedMap[wordLength] = false
        puzzleCompletedMap = completedMap
        focusedIndex = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            shouldAnimateTarget = false
        }
    }

    private func showFinalCelebration() {
        isCelebrating = true
        celebrationStartTime = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showCelebrationCard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCelebrating = false
        }
    }

    private func makeTile(index: Int) -> some View {
        EditableLetterTile(
            index: index,
            wordLength: wordLength,
            userWord: Binding(
                get: { userWordMap[wordLength] ?? "" },
                set: {
                    let oldWord = userWordMap[wordLength] ?? ""
                    var map = userWordMap
                    map[wordLength] = $0
                    userWordMap = map
                    if oldWord != $0 {
                        // Increment changes for the current chain and word length
                        var changesMap = changesMadeMap
                        changesMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] = (changesMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] ?? 0) + 1
                        changesMadeMap = changesMap
                    }
                    validateWord()
                }
            ),
            focusedIndex: $focusedIndex,
            gameLogic: gameLogic,
            onInvalidEntry: {
                showInvalidMessage = true
            },
            externalInvalidTrigger: Binding(
                get: { externalInvalidTriggers[index] ?? false },
                set: { externalInvalidTriggers[index] = $0 }
            ),
            externalInvalidLetter: Binding(
                get: { externalInvalidLetters[index] ?? nil },
                set: { externalInvalidLetters[index] = $0 }
            )
        )
        .modifier(CelebrationTileEffect(
            isActive: isChainCelebrating,
            index: index,
            startTime: celebrationStartTime
        ))
    }

    private func loadAllChainsForToday() {
        let allChains = PuzzleChainLoader.shared.getDailyChains(for: Date(), wordLength: wordLength)
        let previousChainCount = allChainsForToday.count
        allChainsForToday = allChains
        // Only reset currentChainIndex if the chain count has changed and the index is out of bounds
        if !(0..<allChains.count).contains(currentChainIndex) {
            setCurrentChainIndex(0)
        }
        let currentChain = allChainsForToday.isEmpty ? [] : allChainsForToday[currentChainIndex]
        if userWordMap[wordLength] == nil {
            userWordMap[wordLength] = currentChain.first ?? ""
        }
        if puzzleCompletedMap[wordLength] == nil {
            puzzleCompletedMap[wordLength] = false
        }
        if changesMadeMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] == nil {
            changesMadeMap[ChangesKey(wordLength: wordLength, chainIndex: currentChainIndex)] = 0
        }
        focusedIndex = 0
    }

    private var isLastChainSolved: Bool {
        return (currentChainIndex == allChainsForToday.count - 1) && puzzleCompleted
    }

    private func validateWord() {
        let guess = userWordMap[wordLength]?.uppercased() ?? ""
        let target = chain.last?.uppercased() ?? ""
        if guess == target && !guess.isEmpty {
            var completedMap = puzzleCompletedMap
            completedMap[wordLength] = true
            puzzleCompletedMap = completedMap
            // Only show success card if this is the last chain
            if currentChainIndex == allChainsForToday.count - 1 {
                showCelebrationCard = true
            }
            hintActiveByLength[wordLength] = false
            hintDistanceByLength[wordLength] = nil
        }
    }

    // Helper to set the current chain index for the current word length
    private func setCurrentChainIndex(_ idx: Int) {
        currentChainIndexMap[wordLength] = idx
    }
}

// Helper for tile invalid triggers
private struct TileInvalidTriggerKey: PreferenceKey {
    static var defaultValue: [Int: (String) -> Void] = [:]
    static func reduce(value: inout [Int: (String) -> Void], nextValue: () -> [Int: (String) -> Void]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Celebration Effects

struct CelebrationTileEffect: ViewModifier {
    let isActive: Bool
    let index: Int
    let startTime: Date
    @State private var animate: Bool = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.1 : 1.0)
            .shadow(color: animate ? Color.yellow.opacity(0.22) : .clear, radius: animate ? 8 : 0)
            .onAppear {
                if isActive {
                    let delay = Double(index) * 0.05
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            animate = true
                        }
                        // Return to normal after 0.5s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                animate = false
                            }
                        }
                    }
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    let delay = Double(index) * 0.05
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            animate = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                animate = false
                            }
                        }
                    }
                } else {
                    animate = false
                }
            }
    }
}

struct CelebrationConfettiView: View {
    let colors: [Color] = [Color("SeaFoam"), Color("C_SoftCoral"), Color.yellow.opacity(0.7)]
    let count: Int = Int.random(in: 8...12)
    @State private var animate: Bool = false

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { i in
                ConfettiParticle(
                    color: colors[i % colors.count],
                    startX: CGFloat.random(in: 0.1...0.9),
                    delay: Double(i) * 0.07,
                    parentSize: geo.size
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiParticle: View {
    let color: Color
    let startX: CGFloat
    let delay: Double
    let parentSize: CGSize
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 10...18), height: CGFloat.random(in: 10...18))
            .position(x: parentSize.width * startX, y: parentSize.height * 0.75 + yOffset)
            .opacity(opacity)
            .onAppear {
                yOffset = 0
                opacity = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 1.2)) {
                        yOffset = -parentSize.height * CGFloat.random(in: 0.45...0.65)
                        opacity = 0.0
                    }
                }
            }
    }
}

struct CelebrationPulseOverlay: View {
    let isActive: Bool
    @State private var pulse: Double = 0.0
    var body: some View {
        Color.white
            .opacity(pulse)
            .ignoresSafeArea()
            .onChange(of: isActive) { active in
                if active {
                    pulse = 0.0
                    withAnimation(.easeInOut(duration: 0.32)) {
                        pulse = 0.18
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                        withAnimation(.easeInOut(duration: 0.7)) {
                            pulse = 0.0
                        }
                    }
                } else {
                    pulse = 0.0
                }
            }
    }
} 
