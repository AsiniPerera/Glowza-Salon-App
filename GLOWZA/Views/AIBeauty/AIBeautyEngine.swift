import Foundation
import NaturalLanguage // Apple's framework for natural language processing!
import CoreML // Apple's framework for running machine learning models!

// MARK: - Data Transfer Objects (DTOs)
// These structs are used to decode JSON data from BeautyDataStore.
// They act as intermediate models before we map them to the public view models.

private struct ConcernConfig: Codable {
    let name: String
    let icon: String
    let anchors: [String] // Anchor words for semantic matching.
}

private struct TreatmentDTO: Codable {
    let name: String
    let icon: String
    let tagline: String
    let description: String
    let duration: String
    let sessions: String
    let priceRange: String
    let concernTags: [String]
    let semanticAnchors: [String] // Words fed into the embedding model!
}

private struct ProductDTO: Codable {
    let name: String
    let brand: String
    let category: String
    let benefit: String
    let icon: String
    let concernTags: [String]
}

// MARK: - Public View Models
// These are the models that the UI (AIBeautyView) uses to display data.

struct DetectedConcern: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
}

struct TreatmentRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let tagline: String
    let description: String
    let duration: String
    let sessions: String
    let priceRange: String
    let matchScore: Double // 0.0 – 1.0 (computed by ML pipeline)
    let concernTags: [String]
}

struct ProductRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let category: String
    let benefit: String
    let icon: String
}

struct AIBeautyResult {
    let detectedConcerns: [DetectedConcern]
    let treatments: [TreatmentRecommendation]
    let products: [ProductRecommendation]
    var isEmpty: Bool { treatments.isEmpty }
}

// MARK: - AI Beauty Engine
// This is the core logic for the AI chatbot. It uses CoreML and NLP to 
// understand user input and recommend treatments.
final class AIBeautyEngine {

    static let shared = AIBeautyEngine() // Singleton instance!

    // Local CoreML model compiled by Xcode from SkinConcernClassifier.mlmodel
    private let skinModel: MLModel? = {
        guard let url = Bundle.main.url(forResource: "SkinConcernClassifier",
                                        withExtension: "mlmodelc") else { return nil }
        return try? MLModel(contentsOf: url)
    }()

    // Apple's built-in word embedding model — used as fallback when skinModel is nil
    private let embedding: NLEmbedding?

    // Data decoded from JSON strings in BeautyDataStore
    private let treatmentDTOs: [TreatmentDTO]
    private let productDTOs:   [ProductDTO]

    // Public concern list (drives quick-select chips in the UI)
    var concernOptions: [String] { concernConfigs.map(\.name) }

    private let concernConfigs: [ConcernConfig]

    private init() {
        // Load the English word embedding model!
        embedding = NLEmbedding.wordEmbedding(for: .english)
        let decoder = JSONDecoder()
        
        // Decode data from the BeautyDataStore JSON strings!
        concernConfigs = (try? decoder.decode([ConcernConfig].self,
                                              from: Data(BeautyDataStore.concernsJSON.utf8))) ?? []
        treatmentDTOs  = (try? decoder.decode([TreatmentDTO].self,
                                              from: Data(BeautyDataStore.treatmentsJSON.utf8))) ?? []
        productDTOs    = (try? decoder.decode([ProductDTO].self,
                                              from: Data(BeautyDataStore.productsJSON.utf8)))   ?? []
    }

    // MARK: - Public API
    // This is the main function called by the UI. It runs asynchronously on a background thread!
    func analyse(input: String) async -> AIBeautyResult {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return AIBeautyResult(detectedConcerns: [], treatments: [], products: [])
        }
        
        // Offload to a background thread so the main thread (UI) stays responsive!
        return await Task.detached(priority: .userInitiated) { [self] in
            self.runPipeline(on: text)
        }.value
    }

    // MARK: - NLP + ML Pipeline
    // This is where the magic happens! It processes the text in steps.
    private func runPipeline(on text: String) -> AIBeautyResult {
        // Step 1: Tokenize the text (split into words).
        let tokens = tokenize(text)

        // Step 2: Detect skin concerns using CoreML or Embeddings.
        let concerns = detectConcerns(tokens: tokens)
        guard !concerns.isEmpty else {
            return AIBeautyResult(detectedConcerns: [], treatments: [], products: [])
        }
        let concernSet = Set(concerns.map(\.name))

        // Step 3: Score and rank treatments based on matched concerns.
        let treatments = scoreTreatments(tokens: tokens, concernSet: concernSet)

        // Step 4: Match products by concern tags.
        let products = matchProducts(concernSet: concernSet)

        return AIBeautyResult(detectedConcerns: concerns,
                              treatments: treatments,
                              products: products)
    }

    // MARK: - Tokenization
    // Splits the input text into unique words, lowercased, and filters short words.
    private func tokenize(_ text: String) -> [String] {
        var words: [String] = []
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range]).lowercased()
            if word.count >= 3 { words.append(word) } // Only words with 3+ letters!
            return true
        }
        return Array(Set(words)) // Deduplicate words!
    }

    // MARK: - Concern Detection
    // Tries to use CoreML first, and falls back to Word Embeddings if needed.
    private func detectConcerns(tokens: [String]) -> [DetectedConcern] {
        let coreMLHits = detectConcernsCoreML(tokens: tokens)
        // If CoreML didn't find anything, try the embedding fallback!
        return coreMLHits.isEmpty ? detectConcernsEmbedding(tokens: tokens) : coreMLHits
    }

    // Uses the custom CoreML model trained for skin concerns.
    private func detectConcernsCoreML(tokens: [String]) -> [DetectedConcern] {
        guard let model = skinModel else { return [] }

        // Build word-count dict (Bag of Words model).
        var wordCounts = [String: NSNumber]()
        for token in tokens { wordCounts[token] = NSNumber(value: (wordCounts[token]?.doubleValue ?? 0) + 1.0) }
        guard !wordCounts.isEmpty else { return [] }

        do {
            let dictValue = try MLFeatureValue(dictionary: wordCounts as [AnyHashable: NSNumber])
            let provider  = try MLDictionaryFeatureProvider(dictionary: ["wordCounts": dictValue])
            let result    = try model.prediction(from: provider)

            // Read the probability of each class!
            if let probFeat = result.featureValue(for: "skinConcernLabelProbs"),
               let probs    = probFeat.dictionaryValue as? [String: Double] {
                return probs
                    .filter { $0.value > 0.12 } // Only take concerns with > 12% probability!
                    .compactMap { label, _ in
                        concernConfigs.first { $0.name == label }
                            .map { DetectedConcern(name: $0.name, icon: $0.icon) }
                    }
            }

            // Fallback to top-1 label if full probabilities are missing.
            if let label = result.featureValue(for: "skinConcernLabel")?.stringValue {
                let icon = concernConfigs.first { $0.name == label }?.icon ?? "sparkles"
                return [DetectedConcern(name: label, icon: icon)]
            }
        } catch {}
        return []
    }

    // Fallback: Uses word2vec cosine similarity to find matching words.
    private func detectConcernsEmbedding(tokens: [String]) -> [DetectedConcern] {
        concernConfigs.compactMap { config in
            let hit = tokens.contains { token in
                config.anchors.contains { anchor in
                    similarity(token, anchor) > 0.54 // Threshold for match!
                }
            }
            return hit ? DetectedConcern(name: config.name, icon: config.icon) : nil
        }
    }

    // MARK: - Treatment Scoring
    // Scores treatments based on tag matches and semantic similarity.
    private func scoreTreatments(tokens: [String],
                                  concernSet: Set<String>) -> [TreatmentRecommendation] {
        treatmentDTOs
            .compactMap { dto in
                // 1. Tag-overlap score (60% weight).
                let tagScore = Double(dto.concernTags.filter { concernSet.contains($0) }.count)
                             / max(1.0, Double(dto.concernTags.count))

                // 2. Semantic anchor score (40% weight).
                let anchorScore = tokens
                    .flatMap { tok in dto.semanticAnchors.map { similarity(tok, $0) } }
                    .max() ?? 0.0

                let score = tagScore * 0.60 + anchorScore * 0.40
                guard score > 0.14 else { return nil } // Filter out low scores!

                return TreatmentRecommendation(
                    name:        dto.name,
                    icon:        dto.icon,
                    tagline:     dto.tagline,
                    description: dto.description,
                    duration:    dto.duration,
                    sessions:    dto.sessions,
                    priceRange:  dto.priceRange,
                    matchScore:  min(1.0, score),
                    concernTags: dto.concernTags
                )
            }
            .sorted { $0.matchScore > $1.matchScore } // Sort by best match!
    }

    // MARK: - Product Matching
    // Matches products that help with the detected concerns.
    private func matchProducts(concernSet: Set<String>) -> [ProductRecommendation] {
        var seen = Set<String>()
        return productDTOs
            .compactMap { dto -> ProductRecommendation? in
                guard dto.concernTags.contains(where: { concernSet.contains($0) }),
                      seen.insert(dto.name).inserted else { return nil } // Deduplicate!
                return ProductRecommendation(
                    name:     dto.name,
                    brand:    dto.brand,
                    category: dto.category,
                    benefit:  dto.benefit,
                    icon:     dto.icon
                )
            }
            .prefix(6) // Limit to top 6 products!
            .map { $0 }
    }

    // MARK: - Semantic Similarity
    // Calculates how similar two words are using NLEmbedding and string fallbacks.
    private func similarity(_ a: String, _ b: String) -> Double {
        if a == b                              { return 1.00 } // Exact match!
        if a.contains(b) || b.contains(a)     { return 0.85 } // Substring match!
        if a.hasPrefix(b.prefix(4)) || b.hasPrefix(a.prefix(4)) { return 0.65 } // Common prefix!
        
        guard let emb = embedding else        { return 0.00 }
        // NLEmbedding returns distance [0, 1]. We invert it to get similarity!
        return max(0.0, 1.0 - emb.distance(between: a, and: b, distanceType: .cosine))
    }
}
