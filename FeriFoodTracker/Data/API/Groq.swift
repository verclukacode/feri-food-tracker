//
//  Groq.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 11. 1. 26.
//

import Foundation

extension APIManager {
    
    fileprivate func getGroq() -> String {
        return "LALA"
    }

    // MARK: - Groq internal models (text-only)

    private struct GroqChatRequest: Encodable {
        let model: String
        let temperature: Double
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    private struct GroqChatResponse: Decodable {
        let choices: [Choice]?

        struct Choice: Decodable {
            let message: Message?
        }
        struct Message: Decodable {
            let content: String?
        }
    }

    // Exact JSON shape your Express endpoint returns (we only need totals + micros + portion + name)
    private struct GroqAnalyzeResponse: Decodable {
        let name: String?
        let calories: Double?
        let portion_grams: Double?
        let protein: Double?
        let carbs: Double?
        let fat: Double?
        let fiber: Double?
        let sugar: Double?
        let monoFat_g: Double?
        let saturatedFat_g: Double?
        let micronutrients: Micronutrients?

        struct Micronutrients: Decodable {
            let sodium_mg: Double?
            let potassium_mg: Double?
            let iron_mg: Double?
            let calcium_mg: Double?
            let vitaminC_mg: Double?
            let vitaminA_ug: Double?
            let cholesterol_mg: Double?
        }
    }

    /// Text-only Groq nutrition: returns FoodData? via completion, never errors.
    /// - If the text is not food, the model is instructed to output empty/zeros.
    ///   In that case we return `nil` (optional empty result).
    public func fetchFoodDataFromGroqText(
        prompt: String,
        model: String = "meta-llama/llama-4-scout-17b-16e-instruct",
        completion: @escaping (APIManager.FoodData?) -> Void
    ) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            completion(nil)
            return
        }

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            completion(nil)
            return
        }

        let systemPrompt = """
You are a strict JSON generator.

Task:
Given ONE text description, estimate the food's nutritional content as accurately and conservatively as possible.

IMPORTANT:
- If the text is NOT describing food (e.g., random text, objects, people, places, nonsense),
  output the same JSON shape but with:
  - name = ""
  - ingredients = []
  - all numbers = 0
  - foods_on_plate = {}

JSON OUTPUT (output ONLY valid JSON, no explanations):

{
  "name": string,
  "ingredients": [
    {
      "name": string,
      "portion_grams": number,
      "calories": number,
      "protein": number,
      "carbs": number,
      "fat": number,
      "fiber": number,
      "sugar": number
    }
  ],
  "calories": number,
  "portion_grams": number,
  "protein": number,
  "carbs": number,
  "fat": number,
  "fiber": number,
  "sugar": number,
  "monoFat_g": number,
  "saturatedFat_g": number,
  "micronutrients": {
    "sodium_mg": number,
    "potassium_mg": number,
    "iron_mg": number,
    "calcium_mg": number,
    "vitaminC_mg": number,
    "vitaminA_ug": number,
    "cholesterol_mg": number
  },
  "foods_on_plate": {
    "<food_name>": number_in_grams
  }
}

RULES:
- OUTPUT JSON ONLY. NO prose, NO markdown.
- All top-level totals MUST be consistent and realistic.
""".trimmingCharacters(in: .whitespacesAndNewlines)

        let userPrompt = """
Estimate calories/macros from this text and return JSON ONLY:
\(trimmed)
""".trimmingCharacters(in: .whitespacesAndNewlines)

        let payload = GroqChatRequest(
            model: model,
            temperature: 0.15,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ]
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(self.getGroq())", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 15

        do {
            req.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            // Never return errors — just nil
            if error != nil { completion(nil); return }

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let data = data else {
                completion(nil)
                return
            }

            // Parse Groq envelope
            let groq: GroqChatResponse
            do {
                groq = try JSONDecoder().decode(GroqChatResponse.self, from: data)
            } catch {
                completion(nil)
                return
            }

            let content = groq.choices?.first?.message?.content ?? ""

            // Extract JSON object like your Express endpoint
            guard let firstBrace = content.firstIndex(of: "{"),
                  let lastBrace = content.lastIndex(of: "}"),
                  firstBrace < lastBrace else {
                completion(nil)
                return
            }

            let jsonString = String(content[firstBrace...lastBrace])

            // Decode the exact JSON shape
            let analyzed: GroqAnalyzeResponse
            do {
                analyzed = try JSONDecoder().decode(GroqAnalyzeResponse.self, from: Data(jsonString.utf8))
            } catch {
                completion(nil)
                return
            }

            // Non-food => empty/zeros => return nil
            let name = (analyzed.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let calories = analyzed.calories ?? 0
            let portion = analyzed.portion_grams ?? 0
            if name.isEmpty && calories == 0 && portion == 0 {
                completion(nil)
                return
            }

            // Build FoodData nutrients like your other functions
            var foodNutrients: [[String: Any]] = []

            func add(_ nutrientId: Int, _ value: Double?, unit: String) {
                guard let v = value else { return }
                foodNutrients.append([
                    "nutrientId": nutrientId,
                    "value": v,
                    "unitName": unit
                ])
            }

            // Totals
            add(APIManager.FoodData.Nutrient.energyKcal.rawValue, analyzed.calories, unit: "kcal")
            add(APIManager.FoodData.Nutrient.proteinG.rawValue, analyzed.protein, unit: "g")
            add(APIManager.FoodData.Nutrient.carbsG.rawValue, analyzed.carbs, unit: "g")
            add(APIManager.FoodData.Nutrient.fatG.rawValue, analyzed.fat, unit: "g")
            add(APIManager.FoodData.Nutrient.fiberG.rawValue, analyzed.fiber, unit: "g")
            add(APIManager.FoodData.Nutrient.sugarsG.rawValue, analyzed.sugar, unit: "g")

            // Fats
            add(APIManager.FoodData.Nutrient.monoFatG.rawValue, analyzed.monoFat_g, unit: "g")
            add(APIManager.FoodData.Nutrient.satFatG.rawValue, analyzed.saturatedFat_g, unit: "g")

            // Micros
            let micro = analyzed.micronutrients
            add(APIManager.FoodData.Nutrient.sodiumMg.rawValue, micro?.sodium_mg, unit: "mg")
            add(APIManager.FoodData.Nutrient.potassiumMg.rawValue, micro?.potassium_mg, unit: "mg")
            add(APIManager.FoodData.Nutrient.ironMg.rawValue, micro?.iron_mg, unit: "mg")
            add(APIManager.FoodData.Nutrient.calciumMg.rawValue, micro?.calcium_mg, unit: "mg")
            add(APIManager.FoodData.Nutrient.vitaminC_mg.rawValue, micro?.vitaminC_mg, unit: "mg")
            add(APIManager.FoodData.Nutrient.vitaminA_RAE_ug.rawValue, micro?.vitaminA_ug, unit: "µg")
            add(APIManager.FoodData.Nutrient.cholesterolMg.rawValue, micro?.cholesterol_mg, unit: "mg")

            // Build dict your FoodData init expects
            var foodDict: [String: Any] = [
                "description": name,
                "foodNutrients": foodNutrients
            ]

            if let p = analyzed.portion_grams, p > 0 {
                foodDict["servingSize"] = NSNumber(value: p)
                foodDict["servingSizeUnit"] = "g"
            }

            completion(APIManager.FoodData(foodDict: foodDict))
        }.resume()
    }
}
