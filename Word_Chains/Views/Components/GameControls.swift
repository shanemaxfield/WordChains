import SwiftUI

// MARK: - Game Controls View
struct GameControls: View {
    @EnvironmentObject var gameState: GameState
    @FocusState private var focusedIndex: Int?
    @State private var externalInvalidTriggers: [Int: Bool] = [:]
    @State private var externalInvalidLetters: [Int: String?] = [:]
    
    // MARK: - Constants
    private let capsuleWidth: CGFloat = 110
    private let capsuleHeight: CGFloat = 44
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 36)
            lengthSelector
            wordChainGrid
            resetButton
            targetWord
            completionMessage
            newPuzzleButton
            Spacer(minLength: 30)
        }
        .padding(.horizontal, 12)
    }
    
    // MARK: - View Components
    private var lengthSelector: some View {
        HStack(spacing: 18) {
            ForEach(gameState.availableLengths, id: \.self) { length in
                Button(action: {
                    gameState.setWordLength(length)
                }) {
                    Text(gameState.lengthLabels[length] ?? "")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(gameState.currentWordLength == length ? Color("C_PureWhite") : Color("C_Charcoal"))
                        .frame(width: capsuleWidth, height: capsuleHeight)
                        .background(
                            Capsule()
                                .fill(gameState.currentWordLength == length ? Color("C_WarmTeal") : Color("C_PureWhite"))
                        )
                        .overlay(
                            Capsule()
                                .stroke(gameState.currentWordLength == length ? Color("C_WarmTeal") : Color("DustyGray"), lineWidth: 1.2)
                        )
                        .shadow(color: gameState.currentWordLength == length ? Color("C_WarmTeal").opacity(0.15) : Color("C_Charcoal").opacity(0.05), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity)
    }
    
    private var wordChainGrid: some View {
        HStack(spacing: 12) {
            ForEach(0..<max(gameState.currentUserWord.count, gameState.currentWordLength), id: \.self) { index in
                EditableLetterTile(
                    index: index,
                    wordLength: gameState.currentWordLength,
                    userWord: Binding(
                        get: { gameState.currentUserWord },
                        set: { gameState.updateUserWord($0) }
                    ),
                    focusedIndex: $focusedIndex,
                    gameLogic: gameState.currentGameLogic ?? WordChainGameLogic(wordLength: gameState.currentWordLength),
                    externalInvalidTrigger: Binding(
                        get: { externalInvalidTriggers[index] ?? false },
                        set: { externalInvalidTriggers[index] = $0 }
                    ),
                    externalInvalidLetter: Binding(
                        get: { externalInvalidLetters[index] ?? nil },
                        set: { externalInvalidLetters[index] = $0 }
                    )
                )
            }
        }
        .onChange(of: gameState.currentUserWord) { _ in
            validateWord()
        }
        .id(gameState.gridResetTrigger)
        .padding(.vertical, 24)
    }
    
    private var resetButton: some View {
        Button(action: {
            gameState.resetCurrentPuzzle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                Text("Reset")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color("C_PureWhite"))
            .padding(.vertical, 12)
            .padding(.horizontal, 32)
            .background(
                Capsule()
                    .fill(Color("C_WarmTeal"))
            )
            .overlay(
                Capsule()
                    .stroke(Color("C_WarmTeal"), lineWidth: 1.2)
            )
            .shadow(color: Color("C_WarmTeal").opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
    
    private var targetWord: some View {
        Text("Target: \(gameState.currentChain.last ?? "----")")
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundColor(Color("C_Charcoal"))
            .padding(.vertical, 8)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("C_PureWhite"))
                    .shadow(color: Color("C_Charcoal").opacity(0.05), radius: 8, x: 0, y: 4)
            )
    }
    
    private var completionMessage: some View {
        Group {
            if gameState.isCurrentPuzzleCompleted {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color("C_WarmTeal"))
                    Text("🎉 Puzzle Solved!")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(Color("C_WarmTeal"))
                }
                .padding(.vertical, 24)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var newPuzzleButton: some View {
        Button(action: {
            gameState.generateNewPuzzle()
        }) {
            Text("New Puzzle")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color("C_PureWhite"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color("BlueGreenDeep"))
                )
                .overlay(
                    Capsule()
                        .stroke(Color("BlueGreenDeep"), lineWidth: 1.2)
                )
                .shadow(color: Color("BlueGreenDeep").opacity(0.15), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
    
    // MARK: - Private Methods
    private func validateWord() {
        let guess = gameState.currentUserWord.uppercased()
        let target = gameState.currentChain.last ?? ""
        if gameState.currentGameLogic?.isValidWord(guess) == true,
           guess == target {
            gameState.updateUserWord(guess)
        }
    }
} 
