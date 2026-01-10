//
//  APIManager.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 12. 11. 25.
//

import Foundation

enum USDAError: Error {
    case unknown
    case noAPIKey
}

class APIManager {
    
    private static var instance: APIManager?
    public static var shared: APIManager {
        if instance == nil {
            instance = APIManager()
        }
        return instance!
    }
    
    
    public static func getKey() -> String {
        let key1 = "RE".reversed()
        let key2 = "i".uppercased()
        return "LALAF" + key1 + key2
    }
    
    
    public func searchFoods(prompt: String,
                            maxNumberOfResults: Int = 20,
                            completion: @escaping (Result<[FoodData], Error>) -> Void) {

        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        var merged: [FoodData] = []

        // If prompt too short OR we already reached the cap, return early
        if trimmed.count < 3 || merged.count >= maxNumberOfResults {
            completion(.success(Array(merged.prefix(maxNumberOfResults))))
            return
        }

        // Build POST request to your endpoint
        guard let url = URL(string: "https://api.getyoa.app/yoaapi/usda/foods/search") else {
            completion(.success(Array(merged.prefix(maxNumberOfResults))))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "key": APIManager.getKey(),
            "query": trimmed,
            "pageSize": maxNumberOfResults
        ]

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            // If body encoding fails, just return local results
            completion(.success(Array(merged.prefix(maxNumberOfResults))))
            return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let _ = error {
                // Network error — return whatever we have locally
                completion(.success(Array(merged.prefix(maxNumberOfResults))))
                return
            }

            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let data = data else {
                completion(.success(Array(merged.prefix(maxNumberOfResults))))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let root = json as? [String: Any],
                      let foodsArray = root["foods"] as? [[String: Any]] else {
                    // Unexpected shape — just return local
                    completion(.success(Array(merged.prefix(maxNumberOfResults))))
                    return
                }

                let remoteFoods = foodsArray.compactMap { FoodData(foodDict: $0) }
                merged.append(contentsOf: remoteFoods)
                #if canImport(FirebaseAnalytics)
                Analytics.logEvent("food_searched", parameters: ["prompt" : prompt])
                #endif
                completion(.success(Array(merged.prefix(maxNumberOfResults))))
            } catch {
                // Parse error — just return local
                completion(.success(Array(merged.prefix(maxNumberOfResults))))
            }
        }.resume()
    }
    
    
    func fetchFoodData(fromEAN ean: String) async throws -> APIManager.FoodData? {
        // 1) Call OFF product endpoint via POST with JSON body containing ean and api key
        guard let url = URL(string: "https://api.getyoa.app/yoaapi/usda/foods/ean") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body: [String: Any] = [
            "ean": ean,
            "key": APIManager.getKey()
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, _) = try await URLSession.shared.data(for: request)

        // 2) Decode to loosely-typed JSON so we can reshape into FoodData's expected dictionary
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let status = root["status"] as? Int, status == 1,
            let product = root["product"] as? [String: Any]
        else {
            return nil // product not found or unexpected payload
        }

        // 3) Pull name / serving info from OFF
        //    OFF: "product_name" (String), "serving_quantity" (num), "serving_size" (e.g. "15 g")
        let name = (product["product_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var servingSizeValue: NSNumber? = nil
        var servingSizeUnit: String? = nil
        if let q = product["serving_quantity"] as? NSNumber, q.doubleValue > 0 {
            // Try to infer unit from serving_size "15 g", "200 ml", etc.
            if let ss = product["serving_size"] as? String {
                let lower = ss.lowercased()
                if lower.contains("ml") {
                    servingSizeUnit = "ml"
                } else if lower.contains("g") {
                    servingSizeUnit = "g"
                }
            }
            servingSizeUnit = servingSizeUnit ?? "g"
            servingSizeValue = q
        } else if let ss = product["serving_size"] as? String {
            // Fallback: parse a leading number and a unit token from "15 g" / "2 tbsp (37 g)"
            // We'll prefer a value with explicit g/ml inside parentheses if present.
            let lower = ss.lowercased()
            if let parenRange = lower.range(of: #"\((.*?)\)"#, options: .regularExpression) {
                let inside = lower[parenRange]
                if inside.contains("g"), let num = Double(inside.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                    servingSizeValue = NSNumber(value: num)
                    servingSizeUnit = "g"
                } else if inside.contains("ml"), let num = Double(inside.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                    servingSizeValue = NSNumber(value: num)
                    servingSizeUnit = "ml"
                }
            } else if lower.contains(" g"),
                      let num = Double(lower.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                servingSizeValue = NSNumber(value: num)
                servingSizeUnit = "g"
            } else if lower.contains(" ml"),
                      let num = Double(lower.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                servingSizeValue = NSNumber(value: num)
                servingSizeUnit = "ml"
            }
        }

        // 4) Build FoodData.foodNutrients[] from OFF "nutriments"
        //    OFF nutriments are per 100 g (or 100 ml), keys like "fat_100g", "sugars_100g",
        //    plus optional unit keys like "fat_unit". Energy can be in kcal or kJ.
        let nutriments = (product["nutriments"] as? [String: Any]) ?? [:]

        func number(_ value: Any?) -> Double? {
            if let n = value as? NSNumber { return n.doubleValue }
            if let s = value as? String, let d = Double(s) { return d }
            return nil
        }

        // Unit normalization helpers
        enum Want {
            case g, mg, ug, kcal
        }
        func convert(_ v: Double, from offUnit: String?, to want: Want) -> (Double, String) {
            let u = (offUnit ?? "").lowercased()
            switch want {
            case .g:
                // OFF usually gives macros in g already; if mg/µg, convert up
                if u == "mg" { return (v / 1000.0, "g") }
                if u == "µg" || u == "ug" { return (v / 1_000_000.0, "g") }
                return (v, "g")
            case .mg:
                if u == "g" { return (v * 1000.0, "mg") }
                if u == "µg" || u == "ug" { return (v / 1000.0, "mg") }
                return (v, "mg")
            case .ug:
                if u == "mg" { return (v * 1000.0, "µg") }
                if u == "g" { return (v * 1_000_000.0, "µg") }
                return (v, "µg")
            case .kcal:
                // OFF may have energy in kcal or kJ; if kJ, convert: 1 kcal = 4.184 kJ
                if u == "kj" { return (v / 4.184, "kcal") }
                return (v, "kcal")
            }
        }

        // Helper to grab value+unit from OFF nutriments for a given base key
        func off(_ base: String) -> (value: Double?, unit: String?) {
            let val = number(nutriments["\(base)_100g"])
            // sometimes unit key is "<base>_unit", sometimes for energy it's "energy-kcal_unit" or "energy_unit"
            let unitKeyCandidates = ["\(base)_unit", "\(base)_100g_unit"]
            let unit = unitKeyCandidates.compactMap { nutriments[$0] as? String }.first
            return (val, unit)
        }

        // Map OFF -> your Nutrient IDs with desired units
        struct MapItem {
            let offKey: String
            let id: Int
            let want: Want
            // optional alternative unit source (e.g., energy may provide unit on another key)
            let altUnitKeys: [String]
        }

        let M: [MapItem] = [
            .init(offKey: "energy-kcal",           id: APIManager.FoodData.Nutrient.energyKcal.rawValue, want: .kcal, altUnitKeys: ["energy-kcal_unit","energy_unit"]),
            .init(offKey: "proteins",              id: APIManager.FoodData.Nutrient.proteinG.rawValue,   want: .g,    altUnitKeys: []),
            .init(offKey: "fat",                   id: APIManager.FoodData.Nutrient.fatG.rawValue,       want: .g,    altUnitKeys: []),
            .init(offKey: "carbohydrates",         id: APIManager.FoodData.Nutrient.carbsG.rawValue,     want: .g,    altUnitKeys: []),
            .init(offKey: "fiber",                 id: APIManager.FoodData.Nutrient.fiberG.rawValue,     want: .g,    altUnitKeys: []),
            .init(offKey: "sugars",                id: APIManager.FoodData.Nutrient.sugarsG.rawValue,    want: .g,    altUnitKeys: []),

            .init(offKey: "saturated-fat",         id: APIManager.FoodData.Nutrient.satFatG.rawValue,    want: .g,    altUnitKeys: []),
            .init(offKey: "monounsaturated-fat",   id: APIManager.FoodData.Nutrient.monoFatG.rawValue,   want: .g,    altUnitKeys: []),
            .init(offKey: "polyunsaturated-fat",   id: APIManager.FoodData.Nutrient.polyFatG.rawValue,   want: .g,    altUnitKeys: []),
            .init(offKey: "cholesterol",           id: APIManager.FoodData.Nutrient.cholesterolMg.rawValue, want: .mg, altUnitKeys: []),

            .init(offKey: "sodium",                id: APIManager.FoodData.Nutrient.sodiumMg.rawValue,   want: .mg,   altUnitKeys: []),
            .init(offKey: "potassium",             id: APIManager.FoodData.Nutrient.potassiumMg.rawValue, want: .mg,  altUnitKeys: []),
            .init(offKey: "calcium",               id: APIManager.FoodData.Nutrient.calciumMg.rawValue,  want: .mg,   altUnitKeys: []),
            .init(offKey: "iron",                  id: APIManager.FoodData.Nutrient.ironMg.rawValue,     want: .mg,   altUnitKeys: []),

            .init(offKey: "vitamin-a",             id: APIManager.FoodData.Nutrient.vitaminA_RAE_ug.rawValue, want: .ug, altUnitKeys: []),
            .init(offKey: "vitamin-c",             id: APIManager.FoodData.Nutrient.vitaminC_mg.rawValue,     want: .mg, altUnitKeys: []),
            .init(offKey: "vitamin-d",             id: APIManager.FoodData.Nutrient.vitaminD_ug.rawValue,     want: .ug, altUnitKeys: []),
            .init(offKey: "vitamin-e",             id: APIManager.FoodData.Nutrient.vitaminE_mg.rawValue,     want: .mg, altUnitKeys: []),
            .init(offKey: "vitamin-b1",            id: APIManager.FoodData.Nutrient.thiamin_mg.rawValue,      want: .mg, altUnitKeys: []),
            .init(offKey: "vitamin-b2",            id: APIManager.FoodData.Nutrient.riboflavin_mg.rawValue,   want: .mg, altUnitKeys: []),
            .init(offKey: "vitamin-pp",            id: APIManager.FoodData.Nutrient.niacin_mg.rawValue,       want: .mg, altUnitKeys: []), // niacin
            .init(offKey: "vitamin-b6",            id: APIManager.FoodData.Nutrient.vitaminB6_mg.rawValue,    want: .mg, altUnitKeys: []),
            .init(offKey: "folates",               id: APIManager.FoodData.Nutrient.folate_ug.rawValue,       want: .ug, altUnitKeys: []),
            .init(offKey: "vitamin-b12",           id: APIManager.FoodData.Nutrient.vitaminB12_ug.rawValue,   want: .ug, altUnitKeys: []),
        ]

        var foodNutrients: [[String: Any]] = []

        for item in M {
            let (rawVal, rawUnitGuess) = off(item.offKey)
            guard let v = rawVal else { continue }
            // Allow alternative unit key sources when OFF uses a different placement
            let unitFromAlts = item.altUnitKeys.compactMap { nutriments[$0] as? String }.first
            let offUnit = unitFromAlts ?? rawUnitGuess
            let (normVal, normUnit) = convert(v, from: offUnit, to: item.want)

            foodNutrients.append([
                "nutrientId": item.id,
                "value": normVal,
                "unitName": normUnit
            ])
        }

        // 5) Build the dictionary your FoodData init expects
        var foodDict: [String: Any] = [
            "description": name,
            "foodNutrients": foodNutrients
        ]
        if let servingSizeValue, let servingSizeUnit {
            foodDict["servingSize"] = servingSizeValue
            foodDict["servingSizeUnit"] = servingSizeUnit
        }

        // 6) Initialize your FoodData
        return APIManager.FoodData(foodDict: foodDict)
    }
    
    func fetchFoodDataXML(fromEAN ean: String) async throws -> APIManager.FoodData? {
        guard let url = URL(string: "https://api.getyoa.app/yoaapi/usda/foods/ean/xml") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/xml", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "ean": ean,
            "key": APIManager.getKey()
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)

        let parser = FoodDataXMLParser()
        guard let dict = parser.parse(data) else { return nil }

        if let notFound = dict["notFound"] as? Bool, notFound { return nil }

        return APIManager.FoodData(foodDict: dict)
    }
    
}




final class FoodDataXMLParser: NSObject, XMLParserDelegate {
    private(set) var resultDict: [String: Any] = [:]
    private var nutrients: [[String: Any]] = []

    private var currentElement: String = ""
    private var buffer: String = ""

    private var insideNutrient = false
    private var currentNutrientKey: String?
    private var currentNutrientValue: Double?
    private var currentNutrientUnit: String?

    // Map OFF key -> your Nutrient enum rawValue
    // Fill these with YOUR real rawValues:
    private func nutrientId(for key: String) -> Int? {
        switch key {
        case "energy-kcal": return APIManager.FoodData.Nutrient.energyKcal.rawValue
        case "proteins": return APIManager.FoodData.Nutrient.proteinG.rawValue
        case "fat": return APIManager.FoodData.Nutrient.fatG.rawValue
        case "carbohydrates": return APIManager.FoodData.Nutrient.carbsG.rawValue
        case "fiber": return APIManager.FoodData.Nutrient.fiberG.rawValue
        case "sugars": return APIManager.FoodData.Nutrient.sugarsG.rawValue

        case "saturated-fat": return APIManager.FoodData.Nutrient.satFatG.rawValue
        case "monounsaturated-fat": return APIManager.FoodData.Nutrient.monoFatG.rawValue
        case "polyunsaturated-fat": return APIManager.FoodData.Nutrient.polyFatG.rawValue
        case "cholesterol": return APIManager.FoodData.Nutrient.cholesterolMg.rawValue

        case "sodium": return APIManager.FoodData.Nutrient.sodiumMg.rawValue
        case "potassium": return APIManager.FoodData.Nutrient.potassiumMg.rawValue
        case "calcium": return APIManager.FoodData.Nutrient.calciumMg.rawValue
        case "iron": return APIManager.FoodData.Nutrient.ironMg.rawValue

        case "vitamin-a": return APIManager.FoodData.Nutrient.vitaminA_RAE_ug.rawValue
        case "vitamin-c": return APIManager.FoodData.Nutrient.vitaminC_mg.rawValue
        case "vitamin-d": return APIManager.FoodData.Nutrient.vitaminD_ug.rawValue
        case "vitamin-e": return APIManager.FoodData.Nutrient.vitaminE_mg.rawValue
        case "vitamin-b1": return APIManager.FoodData.Nutrient.thiamin_mg.rawValue
        case "vitamin-b2": return APIManager.FoodData.Nutrient.riboflavin_mg.rawValue
        case "vitamin-pp": return APIManager.FoodData.Nutrient.niacin_mg.rawValue
        case "vitamin-b6": return APIManager.FoodData.Nutrient.vitaminB6_mg.rawValue
        case "folates": return APIManager.FoodData.Nutrient.folate_ug.rawValue
        case "vitamin-b12": return APIManager.FoodData.Nutrient.vitaminB12_ug.rawValue
        default: return nil
        }
    }

    func parse(_ data: Data) -> [String: Any]? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { return nil }
        resultDict["foodNutrients"] = nutrients
        return resultDict
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        buffer = ""

        if elementName == "Nutrient" {
            insideNutrient = true
            currentNutrientKey = nil
            currentNutrientValue = nil
            currentNutrientUnit = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)

        if insideNutrient {
            switch elementName {
            case "key":
                currentNutrientKey = text
            case "value":
                currentNutrientValue = Double(text)
            case "unitName":
                currentNutrientUnit = text
            case "Nutrient":
                if
                    let k = currentNutrientKey,
                    let id = nutrientId(for: k),
                    let v = currentNutrientValue,
                    let u = currentNutrientUnit
                {
                    nutrients.append([
                        "nutrientId": id,
                        "value": v,
                        "unitName": u
                    ])
                }
                insideNutrient = false
            default:
                break
            }
        } else {
            switch elementName {
            case "description":
                resultDict["description"] = text
            case "servingSize":
                if let d = Double(text) { resultDict["servingSize"] = NSNumber(value: d) }
            case "servingSizeUnit":
                resultDict["servingSizeUnit"] = text
            case "NotFound":
                resultDict["notFound"] = (text.lowercased() == "true")
            default:
                break
            }
        }

        buffer = ""
    }
}
