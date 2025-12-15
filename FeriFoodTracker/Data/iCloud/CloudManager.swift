//
//  CloudManager.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 1. 10. 25.
//

import CoreData

class CloudManager {
    
    public static var instance: CloudManager?
    public static var shared: CloudManager {
        if instance == nil {
            instance = CloudManager()
        }
        return instance!
    }
    
    
    var persistentContainer: NSPersistentContainer!
    
    
    // MARK: Logs
    func newLog(
        name: String,
        meal: MealType,
        calcium: Double,
        calories: Double,
        carbs: Double,
        fat: Double,
        cholesterol: Double,
        fiber: Double,
        iron: Double,
        monosaturatedFat: Double,
        polyunsaturatedFat: Double,
        portionInGrams: Double,
        potassium: Double,
        protein: Double,
        saturatedFat: Double,
        sodium: Double,
        sugar: Double,
        vitaminA: Double,
        vitaminC: Double,
        date: Date
    ) -> FoodLogData {
        let data = FoodLogData(context: self.persistentContainer.viewContext)
        data.calcium = calcium
        data.calories = calories
        data.carbs = carbs
        data.fat = fat
        data.cholesterol = cholesterol
        data.date = date
        data.fiber = fiber
        data.iron = iron
        data.monosaturatedFat = monosaturatedFat
        data.name = name
        data.polyunsaturatedFat = polyunsaturatedFat
        data.portionInGrams = portionInGrams
        data.potassium = potassium
        data.protein = protein
        data.saturatedFat = saturatedFat
        data.sodium = sodium
        data.sugar = sugar
        data.vitaminA = vitaminA
        data.vitaminC = vitaminC
        data.mealRawValue = meal.rawValue

        // Persist first so objectID is permanent (for the HK metadata ID)
        self.save()

        return data
    }

    func deleteLog(_ log: FoodLogData) {

        // Then remove from Core Data
        self.persistentContainer.viewContext.delete(log)
        
        self.save()
    }
    
    
    func getCalories(for date: Date, completion: @escaping (Double)->()) {
        self.getAll(for: date) { allFoods in
            var calories: Double = 0
            for food in allFoods {
                calories += food.calories
            }
            
            if Calendar.current.isDateInToday(date) {
                UserData.shared.currentCaloriesConsumed = calories
            }
            
            completion(calories)
        }
    }
    
    
    func getAll(for day: Date, completion: @escaping ([FoodLogData])->()) {
        let context = self.persistentContainer.viewContext
        context.perform {
            let request: NSFetchRequest<FoodLogData> = FoodLogData.fetchRequest()
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: day)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                completion([])
                return
            }
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            let result = (try? context.fetch(request)) ?? []
            completion(result)
        }
    }

    func getAll(for day: Date, meal: MealType, completion: @escaping ([FoodLogData])->()) {
        let context = self.persistentContainer.viewContext
        context.perform {
            let request: NSFetchRequest<FoodLogData> = FoodLogData.fetchRequest()
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: day)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                completion([])
                return
            }
            let datePredicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
            let mealPredicate = NSPredicate(format: "mealRawValue == %@", meal.rawValue)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, mealPredicate])
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            let result = (try? context.fetch(request)) ?? []
            completion(result)
        }
    }
    
    
    //MARK: Other
    func save() {
        do {
            try self.persistentContainer.viewContext.save()
        } catch {
            print("Error saving to iCloud")
        }
    }
    
}


public class CloudContainer {
    
    static var mainContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FERIFoodModel")

//        // Configure the shared App Group store location
//        guard let groupURL = FileManager.default.containerURL(
//            forSecurityApplicationGroupIdentifier: "group.deepblue.si.yoanutrition"
//        ) else {
//            fatalError("Shared container URL not found.")
//        }
//        let storeURL = groupURL.appendingPathComponent("FoodLogModel.sqlite")
//
//        // Build a single store description with CloudKit options
//        let description = NSPersistentStoreDescription(url: storeURL)
//        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
//        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
//
//        // IMPORTANT: Enable CloudKit syncing by assigning options with your container identifier
//        // Replace the identifier below with your actual CloudKit container (as set in Signing & Capabilities)
//        let options = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.deepblue.si.yoanutrition")
//        description.cloudKitContainerOptions = options
//
//        // Use exactly one description
//        container.persistentStoreDescriptions = [description]

        // Context configuration
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.retainsRegisteredObjects = false

        container.loadPersistentStores { description, error in
            print(description)
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        // Optional: Observe remote changes for debugging/refresh
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { note in
            print("Received remote change: \(note)")
        }

        return container
    }()

}
