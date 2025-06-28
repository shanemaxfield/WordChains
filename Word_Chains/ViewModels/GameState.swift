import SwiftUI

// MARK: - Game State Models
struct WordChainState: Equatable {
    var chain: [String]
    var userWord: String
    var isCompleted: Bool
    var gameLogic: WordChainGameLogic
    var changesMade: Int
    static func == (lhs: WordChainState, rhs: WordChainState) -> Bool {
        lhs.chain == rhs.chain &&
        lhs.userWord == rhs.userWord &&
        lhs.isCompleted == rhs.isCompleted &&
        lhs.changesMade == rhs.changesMade
        // Note: gameLogic is not compared for equality
    }
}

// MARK: - Persisted State for Free Roam
struct PersistedWordChainState: Codable {
    var chain: [String]
    var userWord: String
    var isCompleted: Bool
    var changesMade: Int
}

// MARK: - Game State Manager
class GameState: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentWordLength: Int = 4
    @Published private(set) var statesByLength: [Int: WordChainState] = [:]
    @Published private(set) var gridResetTrigger: Bool = false
    @Published private(set) var currentDistanceToTargetByLength: [Int: Int?] = [:]
    @Published private(set) var isHintActiveByLength: [Int: Bool] = [:]
    @Published private(set) var isSearchingForChain: [Int: Bool] = [:]
    @Published var showOnboarding: Bool = false
    
    // MARK: - Constants
    let availableLengths = [3, 4, 5]
    let lengthLabels = [3: "3-Letter", 4: "4-Letter", 5: "5-Letter"]
    
    // MARK: - Private Properties
    private var puzzleGenerationTasks: [Int: Task<Void, Never>] = [:]
    
    // MARK: - Initialization
    init() {
        loadOnboardingState()
    }
    
    // MARK: - Onboarding Methods
    func checkAndShowOnboarding() {
        if !hasSeenOnboarding {
            showOnboarding = true
        }
    }
    
    func completeOnboarding() {
        hasSeenOnboarding = true
        showOnboarding = false
        saveOnboardingState()
    }
    
    // For testing purposes - reset onboarding state
    func resetOnboarding() {
        hasSeenOnboarding = false
        showOnboarding = false
        saveOnboardingState()
    }
    
    private var hasSeenOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasSeenOnboarding")
        }
    }
    
    private func loadOnboardingState() {
        // Load onboarding state from UserDefaults
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    private func saveOnboardingState() {
        UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
    }
    
    // MARK: - Public Methods
    func setWordLength(_ length: Int) {
        guard availableLengths.contains(length) else { return }
        currentWordLength = length
        if statesByLength[length] == nil {
            setupGameLogic(for: length)
        }
        
        // If we're showing loading state and there's no ongoing task, start a new search
        if isSearchingForChain[length] == true && puzzleGenerationTasks[length] == nil {
            generateNewPuzzle()
        }
        
        gridResetTrigger.toggle()
        clearHintSteps(for: length)
        persistStatesByLength()
    }
    
    func resetCurrentPuzzle() {
        // If there's no chain or it's empty, generate a new puzzle
        if statesByLength[currentWordLength]?.chain.isEmpty ?? true {
            generateNewPuzzle()
            return
        }
        
        guard let start = statesByLength[currentWordLength]?.chain.first else { return }
        if var state = statesByLength[currentWordLength] {
            state.userWord = start
            state.isCompleted = false
            state.changesMade = 0
            statesByLength[currentWordLength] = state
        }
        gridResetTrigger.toggle()
        clearHintSteps(for: currentWordLength)
        persistStatesByLength()
    }
    
    func generateNewPuzzle() {
        let wordLength = currentWordLength
        guard let logic = statesByLength[wordLength]?.gameLogic else { return }
        isSearchingForChain[wordLength] = true
        
        puzzleGenerationTasks[wordLength] = Task {
            let minLength = 5
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let chainResult = logic.generateRandomShortestChain(minLength: minLength)
                    // Verify that all words in the chain match the current word length
                    let validChain = chainResult.chain.allSatisfy { $0.count == wordLength }
                    if validChain {
                        continuation.resume(returning: chainResult)
                    } else {
                        continuation.resume(returning: ([], "", ""))
                    }
                }
            }
            // If cancelled, do not update state
            if Task.isCancelled {
                await MainActor.run { self.isSearchingForChain[wordLength] = false }
                return
            }
            
            // If no chain found, retry automatically
            if result.chain.isEmpty {
                await MainActor.run { self.isSearchingForChain[wordLength] = false }
                // Small delay before retrying
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if !Task.isCancelled {
                    generateNewPuzzle()
                }
                return
            }
            
            await MainActor.run {
                // Always update the chain, regardless of current word length
                setCurrentChain(result.chain, start: result.start, end: result.end, gameLogic: logic, for: wordLength)
                self.isSearchingForChain[wordLength] = false
                self.puzzleGenerationTasks[wordLength] = nil
            }
        }
    }
    
    func updateUserWord(_ word: String) {
        guard var state = statesByLength[currentWordLength] else { return }
        if state.userWord != word {
            state.changesMade += 1
        }
        state.userWord = word
        validateWord(&state)
        statesByLength[currentWordLength] = state
        // Update distance if hint is active
        if isHintActive {
            let distance = state.gameLogic.getDistanceToTarget(from: word)
            setHintState(distance: distance, active: true, for: currentWordLength)
        }
        persistStatesByLength()
    }
    
    func calculateHintSteps() {
        guard let state = statesByLength[currentWordLength] else { return }
        // Precompute distances to target if not already done
        if let target = state.chain.last {
            state.gameLogic.precomputeDistancesToTarget(target)
            let distance = state.gameLogic.getDistanceToTarget(from: state.userWord)
            setHintState(distance: distance, active: true, for: currentWordLength)
        }
    }

    func clearHintSteps(for length: Int) {
        currentDistanceToTargetByLength[length] = nil
        isHintActiveByLength[length] = false
    }
    
    func setHintState(distance: Int?, active: Bool, for length: Int) {
        currentDistanceToTargetByLength[length] = distance
        isHintActiveByLength[length] = active
    }
    
    func setCurrentChain(_ chain: [String], start: String, end: String, gameLogic: WordChainGameLogic, for length: Int? = nil) {
        let wordLength = length ?? currentWordLength
        // Remove the guard that checks currentWordLength
        guard var state = statesByLength[wordLength] else { return }
        state.chain = chain
        state.userWord = start
        state.isCompleted = false
        state.changesMade = 0
        state.gameLogic = gameLogic
        statesByLength[wordLength] = state
        persistStatesByLength()
    }
    
    func setupGameLogic(for length: Int) {
        let logic = WordChainGameLogic(wordLength: length)
        if statesByLength[length] == nil {
            let result = logic.generateRandomShortestChain(minLength: 5)
            statesByLength[length] = WordChainState(
                chain: result.chain,
                userWord: result.start,
                isCompleted: false,
                gameLogic: logic,
                changesMade: 0
            )
        } else {
            // Update existing state with new game logic
            var state = statesByLength[length]!
            state.gameLogic = logic
            statesByLength[length] = state
        }
    }
    
    // MARK: - Private Methods
    private func validateWord(_ state: inout WordChainState) {
        let guess = state.userWord.uppercased()
        let target = state.chain.last ?? ""
        if state.gameLogic.isValidWord(guess) && guess == target {
            state.isCompleted = true
        }
    }
    
    // MARK: - Computed Properties
    var currentChain: [String] {
        statesByLength[currentWordLength]?.chain ?? []
    }
    
    var currentUserWord: String {
        statesByLength[currentWordLength]?.userWord ?? ""
    }
    
    var isCurrentPuzzleCompleted: Bool {
        statesByLength[currentWordLength]?.isCompleted ?? false
    }
    
    var currentGameLogic: WordChainGameLogic? {
        statesByLength[currentWordLength]?.gameLogic
    }
    
    var minimumChangesNeeded: Int {
        guard let chain = statesByLength[currentWordLength]?.chain,
              chain.count >= 2 else { return 0 }
        return chain.count - 1
    }
    
    var currentChangesMade: Int {
        statesByLength[currentWordLength]?.changesMade ?? 0
    }

    var minimumPossibleChain: [String] {
        guard let chain = statesByLength[currentWordLength]?.chain else { return [] }
        return chain
    }

    var currentDistanceToTarget: Int? {
        currentDistanceToTargetByLength[currentWordLength] ?? nil
    }

    var isHintActive: Bool {
        isHintActiveByLength[currentWordLength] ?? false
    }

    // MARK: - Persistence Helpers
    func exportPersistedStates() -> [Int: PersistedWordChainState] {
        var dict: [Int: PersistedWordChainState] = [:]
        for (length, state) in statesByLength {
            dict[length] = PersistedWordChainState(
                chain: state.chain,
                userWord: state.userWord,
                isCompleted: state.isCompleted,
                changesMade: state.changesMade
            )
        }
        return dict
    }

    func importPersistedStates(_ dict: [Int: PersistedWordChainState]) {
        for (length, persisted) in dict {
            if var state = statesByLength[length] {
                state.chain = persisted.chain
                state.userWord = persisted.userWord
                state.isCompleted = persisted.isCompleted
                state.changesMade = persisted.changesMade
                statesByLength[length] = state
            } else {
                // If not present, create a new state with a default gameLogic
                let logic = WordChainGameLogic(wordLength: length)
                statesByLength[length] = WordChainState(
                    chain: persisted.chain,
                    userWord: persisted.userWord,
                    isCompleted: persisted.isCompleted,
                    gameLogic: logic,
                    changesMade: persisted.changesMade
                )
            }
        }
    }

    private func persistStatesByLength() {
        let export = exportPersistedStates()
        UserDefaults.standard.set(try? JSONEncoder().encode(export), forKey: "freeroam_statesByLength")
    }
} 
