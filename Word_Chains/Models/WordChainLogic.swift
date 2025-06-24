import Foundation

class WordChainGameLogic {
    // MARK: - Properties

    private(set) var wordList: Set<String> = []
    private(set) var currentWordLength: Int = 4
    private var distanceCache: [String: [String: Int]] = [:]
    private var targetDistanceMap: [String: Int] = [:]
    private var currentTarget: String = ""

    // MARK: - Initialization
    init(wordLength: Int) {
        self.currentWordLength = wordLength

        let manager = WordDataManager.shared
        
        // Filter words by length
        self.wordList = manager.validWords.filter { $0.count == wordLength }
    }

    // MARK: - Chain Generation

    func generateRandomShortestChain(
        minLength: Int,
        forcedStart: String? = nil
    ) -> (chain: [String], start: String, end: String) {
        guard !wordList.isEmpty else { return ([], "", "") }

        // Only limit maxLength for 5-letter words
        let maxLength = currentWordLength == 5 ? 8 : Int.max

        for _ in 0..<100 {
            let startWord = forcedStart ?? wordList.randomElement()!
            let endWord = wordList.randomElement()!

            guard startWord != endWord else { continue }

            let chain = findShortestChain(from: startWord, to: endWord)
            if chain.count >= minLength && chain.count <= maxLength {
                return (chain, startWord, endWord)
            }
        }
        return ([], "", "")
    }

    func generateChainFromWord(_ startWord: String, minLength: Int = 5) -> (chain: [String], start: String, end: String) {
        guard !wordList.isEmpty, wordList.contains(startWord) else { return ([], "", "") }
        
        // Only limit maxLength for 5-letter words
        let maxLength = currentWordLength == 5 ? 8 : Int.max
        
        for _ in 0..<100 {
            let endWord = wordList.randomElement()!
            guard startWord != endWord else { continue }
            
            let chain = findShortestChain(from: startWord, to: endWord)
            if chain.count >= minLength && chain.count <= maxLength {
                return (chain, startWord, endWord)
            }
        }
        return ([], "", "")
    }

    // MARK: - Chain Finder (BFS)

    func findShortestChain(from start: String, to end: String) -> [String] {
        guard wordList.contains(start), wordList.contains(end) else { return [] }

        var queue: [(word: String, path: [String])] = [(start, [start])]
        var visited: Set<String> = [start]

        while !queue.isEmpty {
            let (currentWord, path) = queue.removeFirst()
            if currentWord == end { return path }

            let neighbors = wordList.filter { areOneLetterApart($0, currentWord) && !visited.contains($0) }
            for neighbor in neighbors {
                visited.insert(neighbor)
                queue.append((neighbor, path + [neighbor]))
            }
        }
        return []
    }

    // MARK: - Helper

    private func areOneLetterApart(_ w1: String, _ w2: String) -> Bool {
        guard w1.count == w2.count else { return false }
        var diffs = 0
        for (c1, c2) in zip(w1, w2) {
            if c1 != c2 {
                diffs += 1
                if diffs > 1 { return false }
            }
        }
        return diffs == 1
    }

    // MARK: - Validation

    func isValidWord(_ word: String) -> Bool {
        wordList.contains(word.uppercased())
    }

    // MARK: - Distance Calculation

    func precomputeDistancesToTarget(_ target: String) {
        guard wordList.contains(target) else { return }
        // If already cached, use it
        if let cached = distanceCache[target] {
            targetDistanceMap = cached
            currentTarget = target
            return
        }
        // Clear previous target distances
        targetDistanceMap.removeAll()
        currentTarget = target
        // Use BFS to compute all distances to target
        var queue: [(word: String, distance: Int)] = [(target, 0)]
        var visited: Set<String> = [target]
        while !queue.isEmpty {
            let (currentWord, distance) = queue.removeFirst()
            targetDistanceMap[currentWord] = distance
            let neighbors = wordList.filter { areOneLetterApart($0, currentWord) && !visited.contains($0) }
            for neighbor in neighbors {
                visited.insert(neighbor)
                queue.append((neighbor, distance + 1))
            }
        }
        // Cache the result
        distanceCache[target] = targetDistanceMap
    }

    func getDistanceToTarget(from word: String) -> Int {
        return targetDistanceMap[word] ?? -1
    }

    func calculateMinimumSteps(from start: String, to end: String) -> Int {
        // If we have precomputed distances for this target, use them
        if end == currentTarget {
            return getDistanceToTarget(from: start)
        }
        
        // Otherwise use the regular cache
        if let cachedDistances = distanceCache[start],
           let distance = cachedDistances[end] {
            return distance
        }

        // If not in cache, calculate using BFS
        guard wordList.contains(start), wordList.contains(end) else { return -1 }

        var queue: [(word: String, distance: Int)] = [(start, 0)]
        var visited: Set<String> = [start]
        var distances: [String: Int] = [:]

        while !queue.isEmpty {
            let (currentWord, distance) = queue.removeFirst()
            distances[currentWord] = distance

            if currentWord == end {
                // Cache the results
                if distanceCache[start] == nil {
                    distanceCache[start] = [:]
                }
                distanceCache[start]?[end] = distance
                return distance
            }

            let neighbors = wordList.filter { areOneLetterApart($0, currentWord) && !visited.contains($0) }
            for neighbor in neighbors {
                visited.insert(neighbor)
                queue.append((neighbor, distance + 1))
            }
        }

        return -1
    }

    // Clear all caches when word length changes
    func clearCache() {
        distanceCache.removeAll()
        targetDistanceMap.removeAll()
        currentTarget = ""
    }
}
