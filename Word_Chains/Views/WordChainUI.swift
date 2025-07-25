import SwiftUI

struct WordChainUI: View {
    @StateObject private var gameState = GameState()
    @State private var onboardingStep: Int = 0

    var body: some View {
        ZStack {
            // Gradient background for a calming effect
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("C_SoftCream"),
                    Color("C_PureWhite")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GameControls()
        }
        .environmentObject(gameState)
        .overlay(
            OnboardingOverlay(
                isShowing: $gameState.showOnboarding,
                currentStep: $onboardingStep,
                steps: OnboardingData.tutorialSteps,
                onComplete: {
                    gameState.completeOnboarding()
                }
            )
        )
        .onAppear {
            // Check if we should show onboarding
            gameState.checkAndShowOnboarding()
        }
    }
}

// MARK: - Button Style Extensions

extension Button {
    func buttonStyleFilled() -> some View {
        self
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color("BlueGreenDeep"))
            .foregroundColor(Color("C_PureWhite"))
            .cornerRadius(16)
            .shadow(color: Color("BlueGreenDeep").opacity(0.15), radius: 8, x: 0, y: 4)
    }

    func buttonStyleGray() -> some View {
        self
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color("SlateBlueGrey"))
            .foregroundColor(Color("C_PureWhite"))
            .cornerRadius(16)
            .shadow(color: Color("SlateBlueGrey").opacity(0.15), radius: 8, x: 0, y: 4)
    }
} 
