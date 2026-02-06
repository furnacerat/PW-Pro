import SwiftUI
import GoogleGenerativeAI

@MainActor
class GeminiManager: ObservableObject {
    static let shared = GeminiManager()
    
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    private var model: GenerativeModel?
    
    private init() {
        setupModel()
    }
    
    private func setupModel() {
        // Load API Key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let apiKey = dict["GEMINI_API_KEY"] as? String else {
            print("ERROR: GEMINI_API_KEY not found in Config.plist")
            errorMessage = "API Configuration Error"
            return
        }
        
        self.model = GenerativeModel(name: "gemini-1.5-flash", apiKey: apiKey)
    }
    
    struct ImageAnalysisResult {
        let surfaceType: SurfaceType?
        let condition: SurfaceCondition?
        let algaeDensity: Double
        let mossDensity: Double
        let confidence: Double
        let description: String
    }
    
    func analyzeImage(_ image: UIImage) async throws -> ImageAnalysisResult {
        guard let model = model else {
            throw NSError(domain: "GeminiManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not initialized"])
        }
        
        self.isAnalyzing = true
        defer { self.isAnalyzing = false }
        
        // Resize image if too large to save bandwidth/latency
        let processedImage = image // In real app, resize here
        
        let prompt = """
        Analyze this image of a building exterior for professional pressure washing.
        Identify the main surface material (e.g. Vinyl Siding, Brick, Concrete, Wood Deck, Roof Shingles).
        Estimate the level of organic growth (algae, moss, mold) on a scale of 0.0 to 1.0.
        
        Return JSON format:
        {
            "surface": "Vinyl Siding",
            "condition": "Average Soiling",
            "algae_score": 0.5,
            "moss_score": 0.1,
            "confidence": 0.95,
            "description": "Vinyl siding with moderate green algae growth on the north side."
        }
        """
        
        do {
            let response = try await model.generateContent(prompt, processedImage)
            
            if let text = response.text {
                // Parse JSON from text (Gemini might wrap in ```json ... ```)
                let cleanedText = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
                
                if let data = cleanedText.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // Map to our types
                    let surfaceString = json["surface"] as? String ?? ""
                    let surface = mapSurface(surfaceString)
                    
                    let conditionString = json["condition"] as? String ?? ""
                    let condition = mapCondition(conditionString)
                    
                    let algae = json["algae_score"] as? Double ?? 0.0
                    let moss = json["moss_score"] as? Double ?? 0.0
                    let conf = json["confidence"] as? Double ?? 0.8
                    let desc = json["description"] as? String ?? ""
                    
                    return ImageAnalysisResult(
                        surfaceType: surface,
                        condition: condition,
                        algaeDensity: algae,
                        mossDensity: moss,
                        confidence: conf,
                        description: desc
                    )
                }
            }
            
            throw NSError(domain: "GeminiManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
            
        } catch {
            print("Gemini Analysis Error: \(error)")
            throw error
        }
    }
    
    private func mapSurface(_ raw: String) -> SurfaceType {
        // Simple mapping logic - expand as needed
        let lower = raw.lowercased()
        if lower.contains("vinyl") { return .sidingVinyl }
        if lower.contains("brick") { return .sidingBrick }
        if lower.contains("concrete") { return .concreteStd }
        if lower.contains("shingle") { return .roofShingle }
        if lower.contains("wood") || lower.contains("deck") { return .deckWood }
        // Default fallback
        return .sidingVinyl
    }
    
    private func mapCondition(_ raw: String) -> SurfaceCondition {
        let lower = raw.lowercased()
        if lower.contains("heavy") || lower.contains("growth") { return .heavy }
        if lower.contains("light") { return .light }
        return .average
    }
}
