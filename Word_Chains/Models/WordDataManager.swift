import Foundation

class WordDataManager {
    static let shared = WordDataManager()
    
    var validWords: Set<String> = []
    private(set) var didLoadData = false
    
    private init() {}
    
    func loadData() {
        guard !didLoadData else { return }

        // Load words from final_words.csv
        if let wordsPath = Bundle.main.path(forResource: "final_words", ofType: "csv") {
            do {
                let content = try String(contentsOfFile: wordsPath, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                validWords = Set(
                    lines.map { line in
                        line.split(separator: ",").first?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .uppercased() ?? ""
                    }.filter { !$0.isEmpty }

                )
            } catch {
                // ... existing code ...
            }
        } else {
            // ... existing code ...
        }

        didLoadData = true
        // ... existing code ...
    }
}
