//
//  UserGoals.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 1. 10. 25.
//

import Foundation


extension UserData {
    
    var goalCalcium: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalCalcium") == nil {
                store?.set(1.0, forKey: "user.goalCalcium") // 1000 mg
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalCalcium") ?? 1.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalCalcium")
            store?.synchronize()
        }
    }
    
    var goalCalories: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalCalories") == nil {
                store?.set(2200.0, forKey: "user.goalCalories")
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalCalories") ?? 2200.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalCalories")
            store?.synchronize()
        }
    }
    
    var goalCarbs: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalCarbs") == nil {
                store?.set(275.0, forKey: "user.goalCarbs") // ~50% of 2200 kcal
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalCarbs") ?? 275.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalCarbs")
            store?.synchronize()
        }
    }
    
    var goalFat: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalFat") == nil {
                store?.set(73.0, forKey: "user.goalFat") // ~30% of 2200 kcal
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalFat") ?? 73.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalFat")
            store?.synchronize()
        }
    }
    
    var goalCholesterol: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalCholesterol") == nil {
                store?.set(0.3, forKey: "user.goalCholesterol") // 300 mg
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalCholesterol") ?? 0.3
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalCholesterol")
            store?.synchronize()
        }
    }
    
    var goalFiber: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalFiber") == nil {
                store?.set(30.0, forKey: "user.goalFiber") // ~14 g / 1000 kcal
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalFiber") ?? 30.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalFiber")
            store?.synchronize()
        }
    }
    
    var goalIron: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalIron") == nil {
                store?.set(0.018, forKey: "user.goalIron") // 18 mg
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalIron") ?? 0.018
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalIron")
            store?.synchronize()
        }
    }
    
    var goalMonosaturatedFat: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalMonosaturatedFat") == nil {
                store?.set(34.0, forKey: "user.goalMonosaturatedFat") // ~2/3 of unsat
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalMonosaturatedFat") ?? 34.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalMonosaturatedFat")
            store?.synchronize()
        }
    }
    
    var goalPolyunsaturatedFat: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalPolyunsaturatedFat") == nil {
                store?.set(17.0, forKey: "user.goalPolyunsaturatedFat") // ~1/3 of unsat
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalPolyunsaturatedFat") ?? 17.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalPolyunsaturatedFat")
            store?.synchronize()
        }
    }
    
    var goalPotassium: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalPotassium") == nil {
                store?.set(3.4, forKey: "user.goalPotassium") // 3400 mg (adults)
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalPotassium") ?? 3.4
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalPotassium")
            store?.synchronize()
        }
    }
    
    var goalProtein: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalProtein") == nil {
                store?.set(110.0, forKey: "user.goalProtein") // ~20% of 2200 kcal
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalProtein") ?? 110.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalProtein")
            store?.synchronize()
        }
    }
    
    var goalSaturatedFat: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalSaturatedFat") == nil {
                store?.set(22.0, forKey: "user.goalSaturatedFat") // <10% kcal
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalSaturatedFat") ?? 22.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalSaturatedFat")
            store?.synchronize()
        }
    }
    
    var goalSodium: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalSodium") == nil {
                store?.set(2.3, forKey: "user.goalSodium") // 2300 mg
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalSodium") ?? 2.3
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalSodium")
            store?.synchronize()
        }
    }
    
    var goalSugar: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalSugar") == nil {
                store?.set(50.0, forKey: "user.goalSugar") // keep added sugars ≤50 g
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalSugar") ?? 50.0
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalSugar")
            store?.synchronize()
        }
    }
    
    var goalVitaminA: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalVitaminA") == nil {
                store?.set(0.0009, forKey: "user.goalVitaminA") // 900 µg
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalVitaminA") ?? 0.0009
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalVitaminA")
            store?.synchronize()
        }
    }
    
    var goalVitaminC: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.goalVitaminC") == nil {
                store?.set(0.09, forKey: "user.goalVitaminC") // 90 mg
                store?.synchronize()
            }
            return store?.double(forKey: "user.goalVitaminC") ?? 0.09
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.goalVitaminC")
            store?.synchronize()
        }
    }
}


extension UserData {
    
    func setDefaults(forCalories calories: Double, style: DietStyle) {
        self.goalCalories = calories

        let (cPct, pPct, fPct, satFrac, monoFrac, polyFrac, sugarPctKcal, sodiumG, potassiumG): (Double, Double, Double, Double, Double, Double, Double, Double, Double) = {
            switch style {
            case .balanced:
                // USDA Acceptable Macronutrient Distribution Ranges (AMDR)
                return (50, 20, 30, 0.30, 0.50, 0.20, 0.10, 2.3, 3.4)
            case .keto:
                // Keto (lower carb, higher fat)
                return (5, 20, 75, 0.15, 0.50, 0.35, 0.03, 4.0, 4.7)
            case .mildKeto:
                // Mild keto (lower carb, higher fat)
                return (10, 25, 65, 0.10, 0.50, 0.40, 0.05, 4.0, 4.7)
            case .lowCarb:
                // Common “low carb” (not strict keto)
                return (25, 25, 50, 0.20, 0.50, 0.30, 0.07, 3.0, 4.0)
            case .vegan:
                // Plant-based: higher carbs/fiber, moderate fat mostly unsat
                return (55, 20, 25, 0.10, 0.55, 0.35, 0.10, 2.3, 4.7)
            case .vegetarian:
                // Similar to vegan but slightly more fat from dairy/eggs
                return (50, 20, 30, 0.12, 0.50, 0.38, 0.10, 2.3, 4.7)
            case .paleo:
                // Lower carb (no grains), higher protein/fat
                return (30, 30, 40, 0.20, 0.50, 0.30, 0.07, 3.0, 4.7)
            case .mediterranean:
                // Emphasizes olive oil/unsat fat, moderate protein
                return (45, 15, 40, 0.10, 0.60, 0.30, 0.10, 2.3, 4.7)
            case .highProtein:
                // Upper end of AMDR protein
                return (40, 30, 30, 0.20, 0.50, 0.30, 0.10, 2.3, 4.7)
            }
        }()

        // Macros (grams)
        let carbsG   = (calories * cPct / 100.0) / 4.0
        let proteinG = (calories * pPct / 100.0) / 4.0
        let fatG     = (calories * fPct / 100.0) / 9.0

        self.goalCarbs   = carbsG
        self.goalProtein = proteinG
        self.goalFat     = fatG

        // Fat breakdown
        self.goalSaturatedFat       = fatG * satFrac
        self.goalMonosaturatedFat   = fatG * monoFrac
        self.goalPolyunsaturatedFat = fatG * polyFrac

        // Fiber per DRI: 14 g per 1000 kcal
        self.goalFiber = (calories / 1000.0) * 14.0

        // Added sugars (WHO <10% kcal, ideally <5%)
        self.goalSugar = (calories * sugarPctKcal) / 4.0

        // Sodium & potassium
        self.goalSodium    = sodiumG
        self.goalPotassium = potassiumG

        // Core micronutrients (approx DRI for adults)
        self.goalCalcium     = 1.0        // g (1000 mg)
        self.goalIron        = 0.018      // g (18 mg, women of childbearing age)
        self.goalVitaminA    = 0.0009     // g (900 µg RAE)
        self.goalVitaminC    = 0.09       // g (90 mg)
        self.goalCholesterol = 0.3        // g (300 mg, general upper limit)
    }
}
