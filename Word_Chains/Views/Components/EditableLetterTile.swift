import SwiftUI
import UIKit

// MARK: - EditableLetterTile View
struct EditableLetterTile: View {
    // MARK: - Properties
    let index: Int
    let wordLength: Int
    @Binding var userWord: String
    @FocusState.Binding var focusedIndex: Int?
    var gameLogic: WordChainGameLogic
    var onInvalidEntry: (() -> Void)?
    var externalInvalidTrigger: Binding<Bool>
    @Binding var externalInvalidLetter: String?
    
    // MARK: - State
    @State private var localText: String = ""
    @State private var isInvalid: Bool = false
    @State private var pendingInvalidLetter: String? = nil
    @State private var isAnimatingInvalid: Bool = false
    @State private var previousValidLetter: String = ""
    @State private var invalidLetterBounce: Bool = false
    
    // MARK: - Computed Properties
    private var isFocused: Bool { focusedIndex == index }
    private var tilePadding: CGFloat {
        switch wordLength {
        case 5: return 2
        case 4: return 3
        case 3: return 6
        default: return 4
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            tileBackground
            letterInput
        }
        .frame(width: 64, height: 64)
        .contentShape(Rectangle()) // defines hitbox
        .overlay(
            Rectangle()
                .fill(Color.clear)
                .frame(width: 10, height: 10)
                .allowsHitTesting(true)
        )
        .padding(tilePadding) // dynamic spacing between tiles based on word length

        .onTapGesture {
            focusedIndex = index
            Haptics.soft()
        }
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }
    // MARK: - View Components
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(SemanticColors.backgroundMain)
            .shadow(
                color: isFocused ? SemanticColors.accentPrimary.opacity(0.2) : SemanticColors.textPrimary.opacity(0.05),
                radius: isFocused ? 12 : 6,
                x: 0,
                y: isFocused ? 4 : 2
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isFocused ? SemanticColors.accentPrimary : SemanticColors.textSecondary,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
    
    private var letterInput: some View {
        TextField("", text: $localText)
            .focused($focusedIndex, equals: index)
            .onAppear { updateLocalText() }
            .onChange(of: localText) { handleTextChange($0) }
            .onChange(of: externalInvalidLetter) { handleExternalInvalidLetter($0) }
            .onChange(of: userWord) { _ in handleUserWordChange() }
            .onTapGesture { Haptics.soft() }
            .frame(width: 64, height: 64)
            .multilineTextAlignment(.center)
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundColor(isInvalid ? SemanticColors.error : SemanticColors.textTile)
            .scaleEffect(isInvalid && invalidLetterBounce ? 0.82 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.45), value: isInvalid && invalidLetterBounce)
            .background(Color.clear)
            .keyboardType(.asciiCapable)
            .accentColor(.clear)
            .textInputAutocapitalization(.characters)
            .disableAutocorrection(true)
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
    }
    
    // MARK: - Private Methods
    private func updateLocalText() {
        let letters = Array(userWord)
        if index < letters.count {
            localText = String(letters[index])
            previousValidLetter = String(letters[index])
        } else {
            localText = ""
            previousValidLetter = ""
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        let filtered = newValue.uppercased().filter { $0.isLetter }
        if newValue.isEmpty {
            localText = ""
            previousValidLetter = ""
            return
        }
        
        if let last = filtered.last {
            let invalidLetter = String(last)
            var wordArray = Array(userWord)
            if index < wordArray.count {
            wordArray[index] = last
            let newWord = String(wordArray)
            
            if gameLogic.isValidWord(newWord) {
                userWord = newWord
                previousValidLetter = invalidLetter
            } else {
                handleInvalidEntry(invalidLetter)
                }
            }
        }
    }
    
    private func handleInvalidEntry(_ invalidLetter: String) {
        onInvalidEntry?()
        isAnimatingInvalid = true
        localText = invalidLetter
        pendingInvalidLetter = invalidLetter
        isInvalid = true
        invalidLetterBounce = true
        
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
            invalidLetterBounce = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isInvalid = false
                pendingInvalidLetter = nil
                isAnimatingInvalid = false
                localText = previousValidLetter
                invalidLetterBounce = false
            }
        }
    }
    
    private func handleExternalInvalidLetter(_ newValue: String?) {
        guard let invalidLetter = newValue else { return }
        handleInvalidEntry(invalidLetter)
    }
    
    private func handleUserWordChange() {
        if !isAnimatingInvalid {
            updateLocalText()
            let letters = Array(userWord)
            if index < letters.count {
                previousValidLetter = String(letters[index])
            } else {
                previousValidLetter = ""
            }
        }
    }
}

// MARK: - Haptics Helper
struct Haptics {
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
