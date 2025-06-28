// SemanticColors.swift
// Defines semantic color roles for the app UI
//
// Reference Table:
// | Semantic Name         | Asset Name         | Usage Example                        |
// |----------------------|-------------------|--------------------------------------|
// | backgroundMain       | C_PureWhite       | Card backgrounds, overlays           |
// | backgroundSoft       | C_SoftCream       | Gradient backgrounds                 |
// | backgroundPaper      | SandstoneBeige    | Main app background                  |
// | backgroundKeyboard   | SoftSand          | Keyboard, secondary surfaces         |
// | textPrimary          | C_Charcoal        | Main text, headings                  |
// | textSecondary        | DustyGray         | Secondary text, borders              |
// | textTile             | MutedNavy         | Letter tile text                     |
// | accentPrimary        | C_WarmTeal        | Primary actions, focus, success      |
// | accentSecondary      | BlueGreenDeep     | Primary actions, celebration         |
// | accentTertiary       | SlateBlueGrey     | Secondary buttons, navigation        |
// | error                | C_SoftCoral       | Errors, invalid input, reset         |
// | border               | AshGray           | Borders, dividers                    |
// | confetti1            | SeaFoam           | Confetti, celebration                |
// | confetti2            | C_SoftCoral       | Confetti, celebration                |
// | confetti3            | Yellow            | Confetti, celebration                |

import SwiftUI

struct SemanticColors {
    // Backgrounds
    static let backgroundMain = Color("C_PureWhite")
    static let backgroundSoft = Color("C_SoftCream")
    static let backgroundPaper = Color("SandstoneBeige")
    static let backgroundKeyboard = Color("SoftSand")
    
    // Text
    static let textPrimary = Color("C_Charcoal")
    static let textSecondary = Color("DustyGray")
    static let textTile = Color("MutedNavy")
    
    // Accents
    static let accentPrimary = Color("C_WarmTeal")
    static let accentSecondary = Color("BlueGreenDeep")
    static let accentTertiary = Color("SlateBlueGrey")
    
    // Error/Warning
    static let error = Color("C_SoftCoral")
    
    // Borders/Dividers
    static let border = Color("AshGray")
    
    // Celebration/Confetti
    static let confetti1 = Color("SeaFoam")
    static let confetti2 = Color("C_SoftCoral")
    static let confetti3 = Color.yellow.opacity(0.7)
} 