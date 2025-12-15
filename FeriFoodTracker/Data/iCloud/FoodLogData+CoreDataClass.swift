//
//  FoodLogData+CoreDataClass.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 1. 10. 25.
//
//

public import Foundation
public import CoreData

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
}

public typealias FoodLogDataCoreDataClassSet = NSSet

@objc(FoodLogData)
public class FoodLogData: NSManagedObject {

}


extension FoodLogData {
    
    var meal: MealType {
        set(newValue) {
            self.mealRawValue = newValue.rawValue
        } get {
            return MealType(rawValue: self.mealRawValue) ?? .breakfast
        }
    }
    
}


extension FoodLogData {
    
    /// Builds a USDA-like dictionary the `FoodData` init understands (per-100g nutrients + serving info),
    /// then returns a fully usable `FoodData`.
    func convertToUSDAFood() -> APIManager.FoodData? {
        // Guard against 0g to avoid division-by-zero; fall back to 100g “serving”
        let grams = portionInGrams > 0 ? portionInGrams : 100.0
        let scaleToPer100g = 100.0 / grams
        
        // Helpers: scale (to per 100g) + unit mapping
        func g(_ v: Double)  -> Double { v * scaleToPer100g }               // grams stay grams
        func mg(_ v: Double) -> Double { v * 1000.0 * scaleToPer100g }      // stored in g → mg per 100g
        func ug(_ v: Double) -> Double { v * 1_000_000.0 * scaleToPer100g } // stored in g → µg per 100g
        
        // Build the USDA-like "foodNutrients" array (IDs, values per 100g, and units)
        var foodNutrients: [[String: Any]] = []
        func push(_ id: Int, _ val: Double, _ unit: String) {
            foodNutrients.append([
                "nutrientId": id,
                "value": val,
                "unitName": unit
            ])
        }
        
        // Calories (kcal) per 100g
        push(
            APIManager.FoodData.Nutrient.energyKcal.rawValue,
            calories * scaleToPer100g,
            "KCAL"
        )
        
        // Macros (all stored in grams)
        push(APIManager.FoodData.Nutrient.proteinG.rawValue,   g(protein), "G")
        push(APIManager.FoodData.Nutrient.carbsG.rawValue,     g(carbs),   "G")
        push(APIManager.FoodData.Nutrient.fatG.rawValue,       g(fat),     "G")
        push(APIManager.FoodData.Nutrient.fiberG.rawValue,     g(fiber),   "G")
        push(APIManager.FoodData.Nutrient.sugarsG.rawValue,    g(sugar),   "G")
        
        // Fat breakdown (grams)
        push(APIManager.FoodData.Nutrient.satFatG.rawValue,    g(saturatedFat),      "G")
        push(APIManager.FoodData.Nutrient.monoFatG.rawValue,   g(monosaturatedFat),  "G")
        push(APIManager.FoodData.Nutrient.polyFatG.rawValue,   g(polyunsaturatedFat),"G")
        
        // Cholesterol (stored in grams → needs MG)
        push(APIManager.FoodData.Nutrient.cholesterolMg.rawValue, mg(cholesterol), "MG")
        
        // Minerals (stored in grams → MG)
        push(APIManager.FoodData.Nutrient.sodiumMg.rawValue,     mg(sodium),    "MG")
        push(APIManager.FoodData.Nutrient.potassiumMg.rawValue,  mg(potassium), "MG")
        push(APIManager.FoodData.Nutrient.calciumMg.rawValue,    mg(calcium),   "MG")
        push(APIManager.FoodData.Nutrient.ironMg.rawValue,       mg(iron),      "MG")
        
        // Vitamins:
        // - Vitamin A in your model is stored in grams → convert to µg
        push(APIManager.FoodData.Nutrient.vitaminA_RAE_ug.rawValue, ug(vitaminA), "UG")
        // - Vitamin C in grams → mg
        push(APIManager.FoodData.Nutrient.vitaminC_mg.rawValue,     mg(vitaminC), "MG")
        
        // Build a minimal USDA-like payload
        let dict: [String: Any] = [
            "description": name,
            "servingSize": grams,
            "servingSizeUnit": "g",
            "foodMeasures": [
                [
                    "disseminationText": "1 serving",
                    "gramWeight": grams,
                    "rank": 1
                ]
            ],
            "foodNutrients": foodNutrients
        ]
        
        let food = APIManager.FoodData(foodDict: dict)
        food?.isSavedToMyFoods = true
        return food
    }
}
