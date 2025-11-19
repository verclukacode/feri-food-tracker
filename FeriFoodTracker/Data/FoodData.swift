//
//  FoodData.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 12. 11. 25.
//

import Foundation

// MARK: - USDAmanager.FoodData
extension APIManager {
    
    // MARK: - FoodData Model
    public class FoodData {
        
        public var isSavedToMyFoods: Bool = false
        
        // MARK: - Public Properties
        public var name = ""
        public var defaultServingSize: Double = 0 // grams
        
        // MARK: - Internal Storage
        private var rawData: [String : Any] = [:]
        private var per100g: [Int: (value: Double, unit: String)] = [:]
        
        // MARK: - Nutrient IDs
        public enum Nutrient: Int {
            case energyKcal = 1008
            case proteinG   = 1003
            case fatG       = 1004
            case carbsG     = 1005
            case fiberG     = 1079
            case sugarsG    = 2000
            
            case satFatG    = 1258
            case monoFatG   = 1292
            case polyFatG   = 1293
            case cholesterolMg = 1253
            
            case sodiumMg   = 1093
            case potassiumMg = 1092
            case calciumMg  = 1087
            case ironMg     = 1089
            
            case vitaminA_RAE_ug = 1106
            case vitaminC_mg = 1162
            case vitaminD_ug = 1114
            case vitaminE_mg = 1109
            case thiamin_mg  = 1165
            case riboflavin_mg = 1166
            case niacin_mg   = 1167
            case vitaminB6_mg = 1175
            case folate_ug   = 1177
            case vitaminB12_ug = 1178
            // add more as needed
        }
        
        // MARK: - Initializer
        convenience init?(foodDict: [String: Any]) {
            self.init()
            self.name = (foodDict["description"] as? String)
                     ?? (foodDict["foodDescription"] as? String)
                     ?? ""
            self.defaultServingSize =
                FoodData.defaultServingSize(
                    from: foodDict["foodMeasures"] as? [[String: Any]],
                    servingSize: foodDict["servingSize"],
                    servingUnit: foodDict["servingSizeUnit"]
                )
            if let items = foodDict["foodNutrients"] as? [[String: Any]] {
                for n in items {
                    guard
                        let id   = n["nutrientId"] as? Int,
                        let val  = (n["value"] as? NSNumber)?.doubleValue,
                        let unit = n["unitName"] as? String
                    else { continue }
                    per100g[id] = (val, unit)
                }
            }
            self.rawData = foodDict
        }
        
        // MARK: - Default Serving Size
        private static func defaultServingSize(from measures: [[String: Any]]?, servingSize: Any?, servingUnit: Any?) -> Double {
            if let measures, !measures.isEmpty {
                let sorted = measures.sorted { ($0["rank"] as? Int ?? .max) < ($1["rank"] as? Int ?? .max) }
                let looksSingle: (String) -> Bool = { s in
                    let t = s.lowercased()
                    return t.contains("1 ") || t.contains("single")
                }
                if let m = sorted.first(where: {
                    if let t = $0["disseminationText"] as? String, looksSingle(t) { return true }
                    if let t = $0["modifier"] as? String, looksSingle(t) { return true }
                    return false
                }) {
                    return (m["gramWeight"] as? NSNumber)?.doubleValue ?? 100
                }
                return (sorted.first?["gramWeight"] as? NSNumber)?.doubleValue ?? 100
            }
            if let size = servingSize as? NSNumber, let unit = (servingUnit as? String)?.lowercased() {
                let v = size.doubleValue
                switch unit {
                case "g":  return v
                case "mg": return v / 1000.0
                case "kg": return v * 1000.0
                case "oz": return v * 28.349523125
                case "lb": return v * 453.59237
                case "ml": return v
                default:   return 100
                }
            }
            return 100
        }
        
        // MARK: - Generic Scaler
        public func amount(of nutrient: Nutrient, for grams: Double) -> Double? {
            guard let item = per100g[nutrient.rawValue] else { return nil }
            return item.value * grams / 100.0
        }
        
        // MARK: - Raw Accessor
        public func amount(nutrientId: Int, for grams: Double) -> (value: Double, unit: String)? {
            guard let item = per100g[nutrientId] else { return nil }
            return (item.value * grams / 100.0, item.unit)
        }
        
        // MARK: - Calories
        public func calories(for grams: Double) -> Double {
            amount(of: .energyKcal, for: grams) ?? 0
        }
        
        // MARK: - Macros Struct
        public struct Macros {
            public let proteinG: Double
            public let carbsG: Double
            public let fatG: Double
            public let fiberG: Double
            public let sugarsG: Double
            public let satFatG: Double
            public let monoFatG: Double
            public let polyFatG: Double
        }
        
        // MARK: - Macros For Grams
        public func macros(for grams: Double) -> Macros {
            Macros(
                proteinG: amount(of: .proteinG, for: grams) ?? 0,
                carbsG:   amount(of: .carbsG,   for: grams) ?? 0,
                fatG:     amount(of: .fatG,     for: grams) ?? 0,
                fiberG:   amount(of: .fiberG,   for: grams) ?? 0,
                sugarsG:  amount(of: .sugarsG,  for: grams) ?? 0,
                satFatG:  amount(of: .satFatG,  for: grams) ?? 0,
                monoFatG: amount(of: .monoFatG, for: grams) ?? 0,
                polyFatG: amount(of: .polyFatG, for: grams) ?? 0
            )
        }
        
        // MARK: - Micros Struct
        public struct Micros {
            public let sodiumMg: Double
            public let potassiumMg: Double
            public let calciumMg: Double
            public let ironMg: Double
            public let cholesterolMg: Double
            public let vitaminA_RAE_ug: Double
            public let vitaminC_mg: Double
            public let vitaminD_ug: Double
            public let vitaminE_mg: Double
            public let thiamin_mg: Double
            public let riboflavin_mg: Double
            public let niacin_mg: Double
            public let vitaminB6_mg: Double
            public let folate_ug: Double
            public let vitaminB12_ug: Double
        }
        
        // MARK: - Micros For Grams
        public func micros(for grams: Double) -> Micros {
            Micros(
                sodiumMg:         amount(of: .sodiumMg, for: grams) ?? 0,
                potassiumMg:      amount(of: .potassiumMg, for: grams) ?? 0,
                calciumMg:        amount(of: .calciumMg, for: grams) ?? 0,
                ironMg:           amount(of: .ironMg, for: grams) ?? 0,
                cholesterolMg:    amount(of: .cholesterolMg, for: grams) ?? 0,
                vitaminA_RAE_ug:  amount(of: .vitaminA_RAE_ug, for: grams) ?? 0,
                vitaminC_mg:      amount(of: .vitaminC_mg, for: grams) ?? 0,
                vitaminD_ug:      amount(of: .vitaminD_ug, for: grams) ?? 0,
                vitaminE_mg:      amount(of: .vitaminE_mg, for: grams) ?? 0,
                thiamin_mg:       amount(of: .thiamin_mg, for: grams) ?? 0,
                riboflavin_mg:    amount(of: .riboflavin_mg, for: grams) ?? 0,
                niacin_mg:        amount(of: .niacin_mg, for: grams) ?? 0,
                vitaminB6_mg:     amount(of: .vitaminB6_mg, for: grams) ?? 0,
                folate_ug:        amount(of: .folate_ug, for: grams) ?? 0,
                vitaminB12_ug:    amount(of: .vitaminB12_ug, for: grams) ?? 0
            )
        }
        
        // MARK: - Full Panel
        public func allNutrients(for grams: Double) -> [Int: (value: Double, unit: String)] {
            var out: [Int: (Double, String)] = [:]
            for (id, item) in per100g {
                out[id] = (item.value * grams / 100.0, item.unit)
            }
            return out
        }
    }
}
