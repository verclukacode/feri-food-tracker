//
//  FoodLogData+CoreDataProperties.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 1. 10. 25.
//
//

import Foundation
import CoreData


public typealias FoodLogDataCoreDataPropertiesSet = NSSet

extension FoodLogData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodLogData> {
        return NSFetchRequest<FoodLogData>(entityName: "FoodLogData")
    }

    @NSManaged public var calcium: Double
    @NSManaged public var calories: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fat: Double
    @NSManaged public var cholesterol: Double
    @NSManaged public var date: Date
    @NSManaged public var fiber: Double
    @NSManaged public var iron: Double
    @NSManaged public var monosaturatedFat: Double
    @NSManaged public var name: String
    @NSManaged public var polyunsaturatedFat: Double
    @NSManaged public var portionInGrams: Double
    @NSManaged public var potassium: Double
    @NSManaged public var protein: Double
    @NSManaged public var saturatedFat: Double
    @NSManaged public var sodium: Double
    @NSManaged public var sugar: Double
    @NSManaged public var vitaminA: Double
    @NSManaged public var vitaminC: Double
    @NSManaged public var mealRawValue: String

}

extension FoodLogData : Identifiable {

}
