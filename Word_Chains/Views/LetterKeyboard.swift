import SwiftUI

struct LetterKeyboard: View {
    let onLetterTap: (String) -> Void
    let onDelete: () -> Void
    
    private let letters = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(letters, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { letter in
                        Button(action: {
                            Haptics.soft()
                            onLetterTap(letter)
                        }) {
                            Text(letter)
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .frame(width: 32, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color("SoftSand"))
                                        .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color("AshGray").opacity(0.3), lineWidth: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.2),
                                                    Color.white.opacity(0.05)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color("SandstoneBeige").opacity(0.95))
                .shadow(color: Color("AshGray").opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("AshGray").opacity(0.15), lineWidth: 1)
        )
    }
} 
