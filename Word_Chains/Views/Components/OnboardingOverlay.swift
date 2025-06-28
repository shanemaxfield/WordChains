import SwiftUI

struct OnboardingStep {
    let title: String
    let description: String
    let highlightFrame: CGRect?
    let position: OnboardingPosition
    let action: String?
    
    enum OnboardingPosition {
        case top, bottom, left, right, center
    }
}

struct OnboardingOverlay: View {
    @Binding var isShowing: Bool
    @Binding var currentStep: Int
    let steps: [OnboardingStep]
    let onComplete: () -> Void
    
    @State private var highlightFrame: CGRect = .zero
    
    var body: some View {
        if isShowing {
            ZStack {
                // Simplified background - use solid color instead of complex overlay
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Allow tapping outside to advance
                        advanceStep()
                    }
                
                // Current step content
                if currentStep < steps.count {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Tutorial card - simplified styling
                        VStack(spacing: 20) {
                            // Title
                            Text(steps[currentStep].title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color("C_Charcoal"))
                                .multilineTextAlignment(.center)
                            
                            // Description
                            Text(steps[currentStep].description)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color("C_Charcoal"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            // Action buttons
                            VStack(spacing: 16) {
                                // Primary action button
                                if let action = steps[currentStep].action {
                                    Button(action: advanceStep) {
                                        Text(action)
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color("C_PureWhite"))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color("BlueGreenDeep"))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Secondary buttons row
                                HStack(spacing: 16) {
                                    // Back button (only show if not on first step)
                                    if currentStep > 0 {
                                        Button(action: goBack) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "chevron.left")
                                                    .font(.system(size: 16, weight: .medium))
                                                Text("Back")
                                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                            }
                                            .foregroundColor(Color("DustyGray"))
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("DustyGray").opacity(0.6), lineWidth: 1.5)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    Spacer()
                                    
                                    // Skip button
                                    Button(action: skipTutorial) {
                                        Text("Skip Tutorial")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(Color("DustyGray"))
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("DustyGray").opacity(0.6), lineWidth: 1.5)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.top, 8)
                            
                            // Navigation dots
                            HStack(spacing: 8) {
                                ForEach(0..<steps.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentStep ? Color("BlueGreenDeep") : Color("DustyGray"))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.top, 16)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("C_PureWhite"))
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .transition(.opacity) // Simplified transition
                }
            }
            .animation(.easeInOut(duration: 0.2), value: currentStep) // Faster animation
            .animation(.easeInOut(duration: 0.2), value: isShowing) // Faster animation
        }
    }
    
    private func advanceStep() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            withAnimation {
                isShowing = false
            }
            onComplete()
        }
    }
    
    private func skipTutorial() {
        withAnimation {
            isShowing = false
        }
        onComplete()
    }
    
    private func goBack() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
        }
    }
}

// MARK: - Onboarding Data
struct OnboardingData {
    static let tutorialSteps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome to Word Chains! 🎯",
            description: "Transform one word into another by changing one letter at a time. Each step must create a valid word!",
            highlightFrame: nil,
            position: .center,
            action: "Let's Start!"
        ),
        OnboardingStep(
            title: "Choose Your Challenge 📏",
            description: "Select from 3, 4, or 5-letter puzzles. Each length offers different difficulty levels and word possibilities.",
            highlightFrame: nil,
            position: .top,
            action: "Next"
        ),
        OnboardingStep(
            title: "Edit Letter Tiles ✏️",
            description: "Tap on any letter tile to edit it. You can only change one letter at a time, and each change must create a real word.",
            highlightFrame: nil,
            position: .center,
            action: "Got it!"
        ),
        OnboardingStep(
            title: "Follow the Chain 🔗",
            description: "Your goal is to reach the target word shown at the bottom. Each word in your chain must be one letter different from the previous word.",
            highlightFrame: nil,
            position: .bottom,
            action: "Next"
        ),
        OnboardingStep(
            title: "Track Your Progress 📊",
            description: "Watch your change counter - it shows how many letters you've modified. Try to solve puzzles with the fewest changes possible!",
            highlightFrame: nil,
            position: .center,
            action: "Next"
        ),
        OnboardingStep(
            title: "Game Controls 🎮",
            description: "💡 Hint: Shows how many steps to reach the target word\n\n🔄 Reset: Start over with the same puzzle\n\n🆕 New Puzzle/Free Roam: Generate a different word chain\n\n📋 Show Minimum: View the optimal solution after completing",
            highlightFrame: nil,
            position: .center,
            action: "Next"
        ),
        OnboardingStep(
            title: "Reset & New Puzzles 🔄",
            description: "Use 'Reset' to start over with the same puzzle, or 'New Puzzle' to try a completely different word chain!",
            highlightFrame: nil,
            position: .center,
            action: "Start Playing!"
        )
    ]
} 