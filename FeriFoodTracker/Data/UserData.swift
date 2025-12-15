//
//  UserData.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 1. 10. 25.
//

import Foundation


enum AppConfiguration: String {
    case debug = "Debug"
    case testFlight = "TestFlight"
    case appStore = "AppStore"
}


enum DietStyle: String, CaseIterable {
    case balanced = "Balanced"
    case mildKeto = "Mild keto"
    case keto = "Keto"
    case lowCarb = "Low carb"
    case mediterranean = "Mediterranean"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case paleo = "Paleo"
    case highProtein = "High protein"
}


class UserData: NSObject {
    
    private static var instance: UserData?
    public static var shared: UserData {
        if instance == nil {
            instance = UserData()
        }
        return instance!
    }
    
    
    let sharedAppGroup = "group.deepblue.si.yoanutrition"
    
    
    private var isTestFlight: Bool {
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }
    
    private var isDebug: Bool {
        #if DEBUG
          return true
        #else
          return false
        #endif
    }
    
    public var appConfiguration: AppConfiguration {
        if UserData.shared.isDebug {
            return .debug
        } else if UserData.shared.isTestFlight {
            return .testFlight
        } else {
            return .appStore
        }
    }
    
    
    var fullName: String {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.fullName") == nil {
                store?.set("Athlete", forKey: "user.fullName")
                store?.synchronize()
            }
            return store?.object(forKey: "user.fullName") as? String ?? "Athlete"
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.fullName")
            store?.synchronize()
        }
    }
    
    
    var currentCaloriesConsumed: Double {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)!
            let cal = Calendar.current

            // Ensure timestamp exists
            if store.object(forKey: "user.currentCaloriesConsumed.date") == nil {
                store.set(Date(), forKey: "user.currentCaloriesConsumed.date")
                store.set(0.0, forKey: "user.currentCaloriesConsumed")
                store.synchronize()
            }

            // Reset if not today
            if let d = store.object(forKey: "user.currentCaloriesConsumed.date") as? Date,
               !cal.isDateInToday(d) {
                store.set(0.0, forKey: "user.currentCaloriesConsumed")
                store.set(Date(), forKey: "user.currentCaloriesConsumed.date")
                store.synchronize()
            }

            return store.object(forKey: "user.currentCaloriesConsumed") as? Double ?? 0.0
        }
        set {
            let store = UserDefaults(suiteName: sharedAppGroup)!
            store.set(newValue, forKey: "user.currentCaloriesConsumed")
            store.set(Date(), forKey: "user.currentCaloriesConsumed.date")
            store.synchronize()
        }
    }

    private var currentCaloriesConsumedDate: Date {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)!
            if let d = store.object(forKey: "user.currentCaloriesConsumed.date") as? Date {
                return d
            }
            let now = Date()
            store.set(now, forKey: "user.currentCaloriesConsumed.date")
            store.synchronize()
            return now
        }
        set {
            let store = UserDefaults(suiteName: sharedAppGroup)!
            store.set(newValue, forKey: "user.currentCaloriesConsumed.date") // fixed key
            store.synchronize()
        }
    }
    

    var selectedMeal: MealType {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)!
            let cal = Calendar.current

            // Ensure timestamp + value exist
            if store.object(forKey: "user.selectedMeal.date") == nil {
                store.set(Date(), forKey: "user.selectedMeal.date")
            }
            if store.object(forKey: "user.selectedMeal") == nil {
                store.set(MealType.breakfast.rawValue, forKey: "user.selectedMeal")
            }
            store.synchronize()

            // Reset if not today
            if let d = store.object(forKey: "user.selectedMeal.date") as? Date,
               !cal.isDateInToday(d) {
                store.set(MealType.breakfast.rawValue, forKey: "user.selectedMeal")
                store.set(Date(), forKey: "user.selectedMeal.date")
                store.synchronize()
            }

            let raw = store.string(forKey: "user.selectedMeal") ?? MealType.breakfast.rawValue
            return MealType(rawValue: raw) ?? .breakfast
        }
        set {
            let store = UserDefaults(suiteName: sharedAppGroup)!
            store.set(newValue.rawValue, forKey: "user.selectedMeal")
            store.set(Date(), forKey: "user.selectedMeal.date")
            store.synchronize()
        }
    }

    private var selectedMealDate: Date {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)!
            if let d = store.object(forKey: "user.selectedMeal.date") as? Date {
                return d
            }
            let now = Date()
            store.set(now, forKey: "user.selectedMeal.date")
            store.synchronize()
            return now
        }
        set {
            let store = UserDefaults(suiteName: sharedAppGroup)!
            store.set(newValue, forKey: "user.selectedMeal.date") // fixed key
            store.synchronize()
        }
    }
    
    
    var didShowWizard: Bool {
        get {
            let store = UserDefaults(suiteName: sharedAppGroup)
            if store?.object(forKey: "user.didShowWizard") == nil {
                store?.set(false, forKey: "user.didShowWizard")
                store?.synchronize()
            }
            return store?.object(forKey: "user.didShowWizard") as? Bool ?? false
        }
        set(value) {
            let store = UserDefaults(suiteName: sharedAppGroup)
            store?.set(value, forKey: "user.didShowWizard")
            store?.synchronize()
        }
    }
    
}

