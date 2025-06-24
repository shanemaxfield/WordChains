import Foundation

class PuzzleChainLoader {
    static let shared = PuzzleChainLoader()

    struct DayChains: Codable {
        let date: String
        let chains: [[String]]
    }

    private(set) var chainsByLength: [Int: [DayChains]] = [:]

    init() {
        loadChains(forLength: 3, filename: "new_POTD_THREE")
        loadChains(forLength: 4, filename: "new_POTD_FOUR")
        loadChains(forLength: 5, filename: "new_POTD_FIVE")
    }

    private func loadChains(forLength length: Int, filename: String) {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
            return
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return
        }

        do {
            // All new files use the DayChains format
            if filename.hasPrefix("new_POTD_") {
                let parsed = try JSONDecoder().decode([DayChains].self, from: data)
                self.chainsByLength[length] = parsed
            } else {
                // Fallback for old format
                let parsed = try JSONDecoder().decode([[String]].self, from: data)
                self.chainsByLength[length] = [DayChains(date: "", chains: parsed)]
            }
        } catch {
        }
    }

    // Returns all chains for the given date (or closest previous date)
    func getDailyChains(for date: Date, wordLength: Int) -> [[String]] {
        guard let days = chainsByLength[wordLength], !days.isEmpty else {
            return []
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: date)
        // Try to find exact match
        if let match = days.first(where: { $0.date == todayStr }) {
            return match.chains
        }
        // If not found, find the closest previous date
        let sorted = days.sorted { $0.date < $1.date }
        if let prev = sorted.last(where: { $0.date < todayStr }) {
            return prev.chains
        }
        // Fallback to first
        return days.first?.chains ?? []
    }
}

