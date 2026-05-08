import Foundation
import NaturalLanguage
import CoreML


private struct ConcernConfig: Codable {
    let name: String
    let icon: String
    let anchors: [String]
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
    let semanticAnchors: [String]   // anchor words fed into the NL embedding model
}

private struct ProductDTO: Codable {
    let name: String
    let brand: String
    let category: String
    let benefit: String
    let icon: String
    let concernTags: [String]
}

// MARK: - Public View Models  (same interface — no changes needed in AIBeautyView)

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
    let matchScore: Double          // 0.0 – 1.0  (computed by ML pipeline)
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

final class AIBeautyEngine {

    static let shared = AIBeautyEngine()

    // Local CoreML model compiled by Xcode from SkinConcernClassifier.mlmodel
    private let skinModel: MLModel? = {
        guard let url = Bundle.main.url(forResource: "SkinConcernClassifier",
                                        withExtension: "mlmodelc") else { return nil }
        return try? MLModel(contentsOf: url)
    }()

    // Apple's built-in word embedding model — used as fallback when skinModel is nil
    private let embedding: NLEmbedding?

    // Data decoded from JSON strings in BeautyDataStore — not Swift struct literals
    private let treatmentDTOs: [TreatmentDTO]
    private let productDTOs:   [ProductDTO]

    // MARK: - Public concern list  (drives quick-select chips in the UI)
    var concernOptions: [String] { concernConfigs.map(\.name) }

    // Decoded from BeautyDataStore.concernsJSON — zero hardcoding in the engine
    private let concernConfigs: [ConcernConfig]

    private init() {
        embedding = NLEmbedding.wordEmbedding(for: .english)
        let decoder = JSONDecoder()
        // All data decoded from BeautyDataStore JSON — nothing hardcoded in the engine
        concernConfigs = (try? decoder.decode([ConcernConfig].self,
                                              from: Data(BeautyDataStore.concernsJSON.utf8))) ?? []
        treatmentDTOs  = (try? decoder.decode([TreatmentDTO].self,
                                              from: Data(BeautyDataStore.treatmentsJSON.utf8))) ?? []
        productDTOs    = (try? decoder.decode([ProductDTO].self,
                                              from: Data(BeautyDataStore.productsJSON.utf8)))   ?? []
    }

    // MARK: - Public API  (async — NLP runs on a background thread)

    func analyse(input: String) async -> AIBeautyResult {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return AIBeautyResult(detectedConcerns: [], treatments: [], products: [])
        }
        // Offload to a background thread so the main thread stays responsive
        return await Task.detached(priority: .userInitiated) { [self] in
            self.runPipeline(on: text)
        }.value
    }

    // MARK: - NLP + ML Pipeline

    private func runPipeline(on text: String) -> AIBeautyResult {
        let tokens = tokenize(text)

        // Step 1 – detect skin concerns using NLEmbedding cosine similarity
        let concerns = detectConcerns(tokens: tokens)
        guard !concerns.isEmpty else {
            return AIBeautyResult(detectedConcerns: [], treatments: [], products: [])
        }
        let concernSet = Set(concerns.map(\.name))

        // Step 2 – score and rank treatments (tag overlap + embedding similarity)
        let treatments = scoreTreatments(tokens: tokens, concernSet: concernSet)

        // Step 3 – match products by concern tag
        let products = matchProducts(concernSet: concernSet)

        return AIBeautyResult(detectedConcerns: concerns,
                              treatments: treatments,
                              products: products)
    }

    // MARK: - Tokenization  (NLTokenizer — word-level, lowercased, deduplicated)

    private func tokenize(_ text: String) -> [String] {
        var words: [String] = []
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range]).lowercased()
            if word.count >= 3 { words.append(word) }
            return true
        }
        return Array(Set(words))
    }

    // MARK: - Concern Detection
    //   Primary  → local SkinConcernClassifier CoreML model (probability thresholding)
    //   Fallback → NLEmbedding cosine-similarity when model is not in bundle

    private func detectConcerns(tokens: [String]) -> [DetectedConcern] {
        let coreMLHits = detectConcernsCoreML(tokens: tokens)
        return coreMLHits.isEmpty ? detectConcernsEmbedding(tokens: tokens) : coreMLHits
    }

    /// Uses the bundled SkinConcernClassifier.mlmodel.
    /// Input: word-count dict built the same way as the Python training script.
    /// Reads `skinConcernLabelProbs` to surface ALL concerns above a probability floor.
    private func detectConcernsCoreML(tokens: [String]) -> [DetectedConcern] {
        guard let model = skinModel else { return [] }

        // Build word-count dict — mirrors `text_to_word_counts()` in train_skin_model.py
        // MLFeatureValue(dictionary:) requires [AnyHashable: NSNumber]
        var wordCounts = [String: NSNumber]()
        for token in tokens { wordCounts[token] = NSNumber(value: (wordCounts[token]?.doubleValue ?? 0) + 1.0) }
        guard !wordCounts.isEmpty else { return [] }

        do {
            let dictValue = try MLFeatureValue(dictionary: wordCounts as [AnyHashable: NSNumber])
            let provider  = try MLDictionaryFeatureProvider(dictionary: ["wordCounts": dictValue])
            let result    = try model.prediction(from: provider)

            // Use per-class probabilities to detect MULTIPLE concerns in one query
            if let probFeat = result.featureValue(for: "skinConcernLabelProbs"),
               let probs    = probFeat.dictionaryValue as? [String: Double] {
                return probs
                    .filter { $0.value > 0.12 }          // probability floor
                    .compactMap { label, _ in
                        concernConfigs.first { $0.name == label }
                            .map { DetectedConcern(name: $0.name, icon: $0.icon) }
                    }
            }

            // Fallback to top-1 label when probs dict is unavailable
            if let label = result.featureValue(for: "skinConcernLabel")?.stringValue {
                let icon = concernConfigs.first { $0.name == label }?.icon ?? "sparkles"
                return [DetectedConcern(name: label, icon: icon)]
            }
        } catch {}
        return []
    }

    /// NLEmbedding-based fallback — uses word2vec cosine similarity.
    private func detectConcernsEmbedding(tokens: [String]) -> [DetectedConcern] {
        concernConfigs.compactMap { config in
            let hit = tokens.contains { token in
                config.anchors.contains { anchor in
                    similarity(token, anchor) > 0.54
                }
            }
            return hit ? DetectedConcern(name: config.name, icon: config.icon) : nil
        }
    }

    // MARK: - Treatment Scoring  (60 % tag match + 40 % embedding anchor similarity)

    private func scoreTreatments(tokens: [String],
                                  concernSet: Set<String>) -> [TreatmentRecommendation] {
        treatmentDTOs
            .compactMap { dto in
                // Tag-overlap ratio
                let tagScore = Double(dto.concernTags.filter { concernSet.contains($0) }.count)
                             / max(1.0, Double(dto.concernTags.count))

                // Best semantic similarity across all (token, anchor) pairs
                let anchorScore = tokens
                    .flatMap { tok in dto.semanticAnchors.map { similarity(tok, $0) } }
                    .max() ?? 0.0

                let score = tagScore * 0.60 + anchorScore * 0.40
                guard score > 0.14 else { return nil }

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
            .sorted { $0.matchScore > $1.matchScore }
    }

    // MARK: - Product Matching  (concern-tag filter, up to 6 products)

    private func matchProducts(concernSet: Set<String>) -> [ProductRecommendation] {
        var seen = Set<String>()
        return productDTOs
            .compactMap { dto -> ProductRecommendation? in
                guard dto.concernTags.contains(where: { concernSet.contains($0) }),
                      seen.insert(dto.name).inserted else { return nil }
                return ProductRecommendation(
                    name:     dto.name,
                    brand:    dto.brand,
                    category: dto.category,
                    benefit:  dto.benefit,
                    icon:     dto.icon
                )
            }
            .prefix(6)
            .map { $0 }
    }

    // MARK: - Semantic Similarity  [0, 1]
    // Uses NLEmbedding (CoreML) with substring/prefix fallbacks

    private func similarity(_ a: String, _ b: String) -> Double {
        if a == b                              { return 1.00 }
        if a.contains(b) || b.contains(a)     { return 0.85 }
        if a.hasPrefix(b.prefix(4)) || b.hasPrefix(a.prefix(4)) { return 0.65 }
        guard let emb = embedding else        { return 0.00 }
        // NLEmbedding.distance returns cosine distance [0, 1]; convert to similarity
        return max(0.0, 1.0 - emb.distance(between: a, and: b, distanceType: .cosine))
    }
}
