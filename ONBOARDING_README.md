# Word Chains Onboarding System

## Overview
The Word Chains app now includes a comprehensive onboarding tutorial that explains how to play the game to new users. The tutorial appears automatically on first launch and can be replayed anytime via the help button.

## Features

### Automatic First-Time Tutorial
- Shows automatically when a user opens the app for the first time
- Explains all major game mechanics and UI elements
- Can be skipped at any time
- Only shows once per user (stored in UserDefaults)

### Interactive Tutorial Steps
1. **Welcome** - Introduction to the game concept
2. **Word Length Selection** - How to choose puzzle difficulty
3. **Letter Tile Editing** - How to modify letters to create new words
4. **Chain Progression** - Understanding the target word and chain concept
5. **Progress Tracking** - How to monitor your changes and optimize
6. **Game Modes & Options** - Puzzle of the Day vs Free Roam, and puzzle management options
7. **Game Controls** - Reset and new puzzle functionality

### Help Button Access
- Question mark icon in the top-right corner of both main game and Free Roam
- Allows users to replay the tutorial anytime
- Same comprehensive tutorial as first-time experience

### Debug Features (Development Only)
- Reset button (🔄) next to help button in debug builds
- Allows developers to test the onboarding flow
- Resets the "has seen onboarding" state

## Technical Implementation

### Files Modified/Created
- `OnboardingOverlay.swift` - Main tutorial overlay component
- `GameState.swift` - Added onboarding state management
- `WordChainUI.swift` - Integrated onboarding overlay
- `ContentView.swift` - Replaced old welcome message with onboarding
- `GameControls.swift` - Added help button
- `FreeRoamView.swift` - Added help button and onboarding support

### Key Components

#### OnboardingStep
```swift
struct OnboardingStep {
    let title: String
    let description: String
    let highlightFrame: CGRect?
    let position: OnboardingPosition
    let action: String?
}
```

#### OnboardingOverlay
- Semi-transparent background overlay
- Animated card-based tutorial
- Navigation dots showing progress
- Skip functionality
- Smooth transitions between steps

#### GameState Integration
- `showOnboarding: Bool` - Controls tutorial visibility
- `checkAndShowOnboarding()` - Checks if tutorial should show
- `completeOnboarding()` - Marks tutorial as completed
- `resetOnboarding()` - Resets for testing (debug only)

### UserDefaults Storage
- `hasSeenOnboarding` - Boolean flag for first-time status
- Persists across app launches
- Can be reset for testing

## Usage

### For Users
1. **First Launch**: Tutorial appears automatically
2. **Replay Tutorial**: Tap the help button (?) in the top-right
3. **Skip Tutorial**: Tap "Skip Tutorial" at any step
4. **Complete Tutorial**: Tap through all steps or the action button

### For Developers
1. **Test Onboarding**: Use the debug reset button (🔄) in debug builds
2. **Modify Tutorial**: Edit `OnboardingData.tutorialSteps` in `OnboardingOverlay.swift`
3. **Add New Steps**: Create new `OnboardingStep` instances with appropriate content

## Customization

### Adding New Tutorial Steps
```swift
OnboardingStep(
    title: "Your Title",
    description: "Your description text",
    highlightFrame: nil, // Optional: CGRect to highlight UI element
    position: .center,   // .top, .bottom, .left, .right, .center
    action: "Button Text" // Optional: Action button text
)
```

### Styling
- Tutorial cards use the app's color scheme
- Animations are smooth and consistent with app design
- Text uses the app's font system and weights

## Future Enhancements
- Highlight specific UI elements during tutorial
- Interactive tutorial steps (tap to demonstrate)
- Video tutorial option
- Localized tutorial content
- Tutorial for advanced features 