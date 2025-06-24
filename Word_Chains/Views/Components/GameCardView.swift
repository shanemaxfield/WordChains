import SwiftUI

struct GameCardView: View {
    let tilesCount: Int
    let makeTile: (Int) -> AnyView
    let targetWord: String
    let showReset: Bool
    let onReset: (() -> Void)?
    let showFreeRoam: Bool
    let onFreeRoam: (() -> Void)?
    let cardColor: Color
    let puzzleCompleted: Bool
    let invalidMessage: String?
    let showInvalidMessage: Bool
    let showSuccess: Bool
    let successMessage: String?
    let onSuccessAction: (() -> Void)?
    let successActionLabel: String?
    let minimumChanges: Int
    let onHint: (() -> Void)?
    let currentDistance: Int?
    let isHintActive: Bool
    let bottomRightButton: (() -> AnyView)?
    let shouldAnimateTarget: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 8) {
                Spacer().frame(height: 26)
                HStack(spacing: tilesCount == 5 ? 8 : 12) {
                    ForEach(0..<tilesCount, id: \.self) { index in
                        makeTile(index)
                    }
                }
                .padding(.vertical, 8)
                .padding(.bottom, 10)
                .frame(height: 64)

                Spacer().frame(height: 8)

                Text(showInvalidMessage && invalidMessage != nil ? invalidMessage! : " ")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color("C_SoftCoral"))
                    .multilineTextAlignment(.center)
                    .opacity(showInvalidMessage && invalidMessage != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showInvalidMessage)

                Spacer().frame(height: 4)

                HStack(spacing: 16) {
                    Text("Minimum Changes: \(minimumChanges)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color("C_Charcoal").opacity(0.5))
                    
                    if isHintActive, let distance = currentDistance {
                        Text("Steps to Target: \(distance)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color("C_WarmTeal"))
                    }
                }
                .padding(.vertical, 4)
                .frame(height: 24)

                HStack(spacing: 12) {
                    if showReset, let onReset = onReset, !puzzleCompleted {
                        Button(action: onReset) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color("C_PureWhite"))
                                .frame(width: 70, height: 40)
                                .background(Capsule().fill(Color("C_SoftCoral")))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .clipShape(Capsule())
                        .shadow(color: Color("C_SoftCoral").opacity(0.10), radius: 4, x: 0, y: 2)
                    }
                    
                    if let onHint = onHint, !puzzleCompleted {
                        Button(action: onHint) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color("C_PureWhite"))
                                .frame(width: 70, height: 40)
                                .background(Capsule().fill(Color("C_WarmTeal")))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .clipShape(Capsule())
                        .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
                    }
                    
                    if let bottomRightButton = bottomRightButton {
                        bottomRightButton()
                            .frame(width: 70, height: 40)
                            .background(Capsule().fill(Color("SlateBlueGrey")))
                            .clipShape(Capsule())
                            .shadow(color: Color("SlateBlueGrey").opacity(0.10), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 40)
                .padding(.top, 5)
                .padding(.bottom, -8)

                // Target word display
                HStack(spacing: 8) {
                    Text("Target:")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("C_Charcoal"))
                    AnyView(
                        Text(targetWord)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("C_Charcoal"))
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.4).combined(with: .opacity),
                        removal: .scale(scale: 1.8).combined(with: .opacity)
                    ))
                    .id(targetWord) // Force view recreation when target word changes
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .animation(shouldAnimateTarget ? .spring(response: 0.6, dampingFraction: 0.4) : nil, value: targetWord)

                Spacer(minLength: 0)
            }
            .frame(height:270)
            .padding(.vertical, 24)
            .padding(.horizontal, tilesCount == 5 ? 8 : 24)
            .background(cardColor.opacity(0.98))
            .cornerRadius(24)
            .shadow(color: Color("C_Charcoal").opacity(0.07), radius: 16, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color("C_Charcoal").opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 8)
        }
    }
} 
 
