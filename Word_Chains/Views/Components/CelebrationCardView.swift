import SwiftUI

struct FixedWidthContainer<Content: View>: View {
    let content: Content
    let width: CGFloat
    let showCardBackground: Bool
    let showBorder: Bool
    let backgroundColor: Color
    let horizontalPadding: CGFloat

    init(width: CGFloat = 280,
         showCardBackground: Bool = true,
         showBorder: Bool = false,
         backgroundColor: Color = Color("C_PureWhite"),
         horizontalPadding: CGFloat = 12,
         @ViewBuilder content: () -> Content) {
        self.width = width
        self.showCardBackground = showCardBackground
        self.showBorder = showBorder
        self.backgroundColor = backgroundColor
        self.horizontalPadding = horizontalPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(.vertical, 6)
            .padding(.horizontal, horizontalPadding)
            .background(
                showCardBackground ?
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color("AshGray").opacity(0.25), lineWidth: 1.2)
                        )
                        .shadow(color: Color("C_Charcoal").opacity(0.08), radius: 8, x: 0, y: 4)
                : nil
            )
            .frame(width: width)
    }
}

struct CelebrationCardView: View {
    var onRetry: () -> Void
    var onShowMinimum: () -> Void
    var onNext: (() -> Void)?
    var onFreeRoam: (() -> Void)?
    var onContinueChain: (() -> Void)?
    var changesMade: Int
    var minimumChanges: Int
    var showFreeRoamButton: Bool
    var showMinimumChain: Bool
    var minimumChain: [String]
    var minimumChainGroups: [[String]]? = nil
    var onWordLengthChange: ((Int) -> Void)? = nil
    var currentWordLength: Int = 4
    @State private var selectedChainIndex: Int = 0
    @Namespace private var morphNamespace
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack(alignment: .topLeading) {
                if showMinimumChain {
                    Button(action: onShowMinimum) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color("C_Charcoal"))
                            .padding(16)
                            .contentShape(Rectangle())
                    }
                    .zIndex(2)
                }
                VStack(spacing: 20) {
                    if showMinimumChain, let groups = minimumChainGroups, !groups.isEmpty {
                        // Morphing Button <-> Minimum Chain Display
                        HStack {
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color("BlueGreenDeep"))
                                    .matchedGeometryEffect(id: "showMinimumMorph", in: morphNamespace)
                                    .frame(width: 210, height: 340)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color("BlueGreenDeep"), lineWidth: 1.2)
                                    )
                                    .shadow(color: Color("BlueGreenDeep").opacity(0.10), radius: 8, x: 0, y: 4)
                                TabView(selection: $selectedChainIndex) {
                                    ForEach(groups.indices, id: \.self) { idx in
                                        FixedWidthContainer(
                                            width: 150,
                                            showCardBackground: false,
                                            showBorder: false,
                                            backgroundColor: Color.clear,
                                            horizontalPadding: 0
                                        ) {
                                            let chain = groups[idx]
                                            ZStack(alignment: .top) {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color("C_PureWhite").opacity(0.5), lineWidth: 2)
                                                Group {
                                                    if chain.count > 7 {
                                                        ScrollView {
                                                            VStack(spacing: 8) {
                                                                Text("Chain #\(idx + 1)")
                                                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                                                    .foregroundColor(Color("C_PureWhite").opacity(0.9))
                                                                ForEach(chain.indices, id: \.self) { i in
                                                                    Text(chain[i])
                                                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                                        .foregroundColor(Color("C_PureWhite"))
                                                                    if i < chain.count - 1 {
                                                                        Image(systemName: "arrow.down")
                                                                            .font(.system(size: 8, weight: .medium))
                                                                            .foregroundColor(Color("C_PureWhite").opacity(0.6))
                                                                    }
                                                                }
                                                            }
                                                            .padding(.vertical, 12)
                                                            .padding(.horizontal, 8)
                                                        }
                                                    } else {
                                                        VStack(spacing: 8) {
                                                            Text("Chain #\(idx + 1)")
                                                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                                                .foregroundColor(Color("C_PureWhite").opacity(0.9))
                                                            VStack(spacing: 6) {
                                                                ForEach(chain.indices, id: \.self) { i in
                                                                    Text(chain[i])
                                                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                                        .foregroundColor(Color("C_PureWhite"))
                                                                    if i < chain.count - 1 {
                                                                        Image(systemName: "arrow.down")
                                                                            .font(.system(size: 8, weight: .medium))
                                                                            .foregroundColor(Color("C_PureWhite").opacity(0.6))
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        .padding(.vertical, 12)
                                                        .padding(.horizontal, 8)
                                                    }
                                                }
                                            }
                                            .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(.vertical, 6)
                                        .tag(idx)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(width: 190, height: 320)
                            }
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(Color("C_WarmTeal"))
                            Text("Puzzle Complete!")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color("C_Charcoal"))
                        }
                        .padding(.top, 16)
                        .padding(.vertical, 4)
                        
                        FixedWidthContainer {
                            VStack(spacing: 12) {
                                Text("Changes Made: \(changesMade)")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(Color("C_Charcoal"))
                                Text("Minimum Possible: \(minimumChanges)")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("C_Charcoal").opacity(0.5))
                            }
                        }
                        
                        VStack(spacing: 16) {
                            // First row: Word length buttons
                            HStack(spacing: 12) {
                                if let onWordLengthChange = onWordLengthChange {
                                    ForEach([3, 4, 5].filter { $0 != currentWordLength }, id: \.self) { length in
                                        Button(action: { onWordLengthChange(length) }) {
                                            Text("\(length) Letter")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color("C_PureWhite"))
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .lineLimit(1)
                                        .layoutPriority(1)
                                        .background(
                                            Capsule()
                                                .fill(Color("BlueGreenDeep"))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color("BlueGreenDeep"), lineWidth: 1.2)
                                        )
                                        .shadow(color: Color("BlueGreenDeep").opacity(0.15), radius: 8, x: 0, y: 4)
                                    }
                                }
                            }
                            // Second row: Retry, Show Minimum, Next Puzzle, Free Roam buttons
                            HStack(spacing: 12) {
                                Button(action: onRetry) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(width: 70, height: 40)
                                        .background(Capsule().fill(Color("C_WarmTeal")))
                                        .overlay(
                                            Capsule().stroke(Color("C_WarmTeal"), lineWidth: 1.2)
                                        )
                                        .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Button(action: {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                        onShowMinimum()
                                    }
                                }) {
                                    ZStack {
                                        Capsule()
                                            .fill(Color("C_WarmTeal"))
                                            .matchedGeometryEffect(id: "showMinimumMorph", in: morphNamespace)
                                            .frame(width: 70, height: 40)
                                            .overlay(
                                                Capsule().stroke(Color("C_WarmTeal"), lineWidth: 1.2)
                                            )
                                            .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
                                        Image(systemName: "list.bullet")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                // Next Puzzle button (if onNext is provided)
                                if let onNext = onNext {
                                    Button(action: onNext) {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(width: 70, height: 40)
                                            .background(Capsule().fill(Color("C_WarmTeal")))
                                            .overlay(
                                                Capsule().stroke(Color("C_WarmTeal"), lineWidth: 1.2)
                                            )
                                            .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                if showFreeRoamButton, let onFreeRoam = onFreeRoam {
                                    Button(action: onFreeRoam) {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(width: 70, height: 40)
                                            .background(Capsule().fill(Color("C_WarmTeal")))
                                            .overlay(
                                                Capsule().stroke(Color("C_WarmTeal"), lineWidth: 1.2)
                                            )
                                            .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: showMinimumChain)
            }
        }
        .frame(width: 280)
        .frame(minHeight: 420)
        .padding(.horizontal, 32)
        .padding(.vertical, 36)
        .background(Color("C_PureWhite"))
        .cornerRadius(32)
        .shadow(color: Color("C_Charcoal").opacity(0.08), radius: 24, x: 0, y: 12)
        .frame(width: 280, height: 420)
    }
}
