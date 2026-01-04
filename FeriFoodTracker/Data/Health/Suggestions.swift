//
//  Suggestions.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 7. 10. 25.
//

import UIKit

class HealthManager {
    static let shared = HealthManager()
}

extension HealthManager {
    
    private struct UpperScaling {
        static let calories: Double = 1.10
        static let carbs: Double = 1.15
        static let protein: Double = 1.20
        static let fat: Double = 1.15
        static let fiber: Double = 1.25
        static let sugar: Double = 1.00
        static let saturatedFat: Double = 1.00
        static let monounsaturatedFat: Double = 1.25
        static let cholesterol: Double = 1.00
        static let sodium: Double = 1.00
        static let potassium: Double = 1.10
        static let vitaminA: Double = 1.10
        static let vitaminC: Double = 1.25
        static let calcium: Double = 1.10
        static let iron: Double = 1.10
    }
    
    func getSuggestions(completion: @escaping ([SuggestionsData])->()) {
        let calendar = Calendar.current
        
        var caloriesDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var carbsDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var proteinDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var fatDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        
        var fiberDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var sugarDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var saturatedFatDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var monounsaturatedFatDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var cholesterolDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var sodiumDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var potassiumDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var vitaminADays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var vitaminCDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var calciumDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        var ironDays: [(Double, Date)] = Array(repeating: (0, Date.now), count: 10)
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "suggestions", attributes: .concurrent)
                    
        for i in 0..<10 {
            if let date = calendar.date(byAdding: .day, value: -(i + 1), to: .now) {
                group.enter()
                queue.async {
                    CloudManager.shared.getAll(for: date) { allFood in
                        caloriesDays[i] = (allFood.map(\.calories).reduce(0, +), date)
                        carbsDays[i] = (allFood.map(\.carbs).reduce(0, +), date)
                        proteinDays[i] = (allFood.map(\.protein).reduce(0, +), date)
                        fatDays[i] = (allFood.map(\.fat).reduce(0, +), date)
                        
                        fiberDays[i] = (allFood.map(\.fiber).reduce(0, +), date)
                        sugarDays[i] = (allFood.map(\.sugar).reduce(0, +), date)
                        saturatedFatDays[i] = (allFood.map(\.saturatedFat).reduce(0, +), date)
                        monounsaturatedFatDays[i] = (allFood.map(\.monosaturatedFat).reduce(0, +), date)
                        cholesterolDays[i] = (allFood.map(\.cholesterol).reduce(0, +), date)
                        sodiumDays[i] = (allFood.map(\.sodium).reduce(0, +), date)
                        potassiumDays[i] = (allFood.map(\.potassium).reduce(0, +), date)
                        vitaminADays[i] = (allFood.map(\.vitaminA).reduce(0, +), date)
                        vitaminCDays[i] = (allFood.map(\.vitaminC).reduce(0, +), date)
                        calciumDays[i] = (allFood.map(\.calcium).reduce(0, +), date)
                        ironDays[i] = (allFood.map(\.iron).reduce(0, +), date)
                        
                        group.leave()
                    }
                }
            }
        }
                    
        group.notify(queue: .global(qos: .userInitiated)) {
            
            var suggestions: [SuggestionsData] = []
            
            // Too little calories
            let littleCaloriesCount = caloriesDays.filter {
                $0.0 < UserData.shared.goalCalories * 0.9 &&
                ($0.0 != 0)
            }.count
            if littleCaloriesCount >= 3 {
                suggestions.append(SuggestionsData(
                    id: "calories.little",
                    title: "Calories not reached",
                    icon: UIImage(systemName: "flame.fill"),
                    description: "In the past 10 days, youd didn't reach you calorie goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleCaloriesCount)"),
                    color: .systemPurple,
                    graph: caloriesDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalCalories * UpperScaling.calories,
                        y: UserData.shared.goalCalories * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 1.0 * Double(littleCaloriesCount),
                    answer: "Consistently eating less than your calorie goal can leave you tired, hungrier, and make it harder to recover or build muscle over time. Try adding a small balanced snack or slightly larger portions of whole foods (grains, healthy fats, and protein) so your intake better matches your goal.".localized(),
                    tag: .body
                ))
            }
            
            // Too much calories
            let muchCaloriesCount = caloriesDays.filter {
                $0.0 > UserData.shared.goalCalories * UpperScaling.calories &&
                ($0.0 != 0)
            }.count
            if muchCaloriesCount >= 3 {
                suggestions.append(SuggestionsData(
                    id: "calories.much",
                    title: "Calories exceeded",
                    icon: UIImage(systemName: "flame.fill"),
                    description: "In the past 10 days, you exceeded your calorie goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchCaloriesCount)"),
                    color: .systemOrange,
                    graph: caloriesDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalCalories * UpperScaling.calories,
                        y: UserData.shared.goalCalories * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 1.0 * Double(muchCaloriesCount),
                    answer: "Regularly going over your calorie goal can make weight gain more likely and may leave you feeling sluggish. To rebalance, try slightly smaller portions, swap sugary drinks and sweets for water and fruit, and fill more of your plate with vegetables and lean protein.".localized(),
                    tag: .body
                ))
            }
            
            // Too little carbs
            let littleCarbsCount = carbsDays.filter { carbsDay in
                carbsDay.0 < UserData.shared.goalCarbs * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: carbsDay.1) }?.0 ?? 0) != 0
            }.count
            if littleCarbsCount >= 3 {
                suggestions.append(SuggestionsData(
                    id: "carbs.little",
                    title: "Carbs not reached",
                    icon: UIImage(systemName: "takeoutbag.and.cup.and.straw.fill"),
                    description: "In the past 10 days, you didn't reach your carbs goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleCarbsCount)"),
                    color: .systemBlue,
                    graph: carbsDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalCarbs * UpperScaling.carbs,
                        y: UserData.shared.goalCarbs * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.7 * Double(littleCarbsCount),
                    answer: "Too few carbs can leave you low on energy, make workouts feel harder, and cause brain fog for some people. Try adding more whole grains, potatoes, rice, fruit, or beans—especially around times you’re active—to support steady energy.".localized(),
                    tag: .body
                ))
            }
            
            // Too much carbs
            let muchCarbsCount = carbsDays.filter { carbsDay in
                carbsDay.0 > UserData.shared.goalCarbs * UpperScaling.carbs &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: carbsDay.1) }?.0 ?? 0) != 0
            }.count
            if muchCarbsCount >= 3 {
                suggestions.append(SuggestionsData(
                    id: "carbs.much",
                    title: "Carbs exceeded",
                    icon: UIImage(systemName: "takeoutbag.and.cup.and.straw.fill"),
                    description: "In the past 10 days, you exceeded your carbs goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchCarbsCount)"),
                    color: .systemOrange,
                    graph: carbsDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalCarbs * UpperScaling.carbs,
                        y: UserData.shared.goalCarbs * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.7 * Double(muchCarbsCount),
                    answer: "A lot of refined carbs and sweets can cause big swings in energy and make it easier to gain weight over time. Try swapping white bread, pastries, and sugary drinks for whole grains, fruit, and water, and spread carb-rich foods more evenly across the day.".localized(),
                    tag: .body
                ))
            }
            
            // Too little protein
            let littleProteinCount = proteinDays.filter { proteinDay in
                proteinDay.0 < UserData.shared.goalProtein * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: proteinDay.1) }?.0 ?? 0) != 0
            }.count
            if littleProteinCount >= 3 {
                suggestions.append(SuggestionsData(
                    id: "protein.little",
                    title: "Protein not reached",
                    icon: UIImage(systemName: "bolt.fill"),
                    description: "In the past 10 days, you didn't reach your protein goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleProteinCount)"),
                    color: .systemPurple,
                    graph: proteinDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalProtein * UpperScaling.protein,
                        y: UserData.shared.goalProtein * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.9 * Double(littleProteinCount),
                    answer: "Low protein intake over time can make it harder to maintain muscle, recover from exercise, and feel full after meals. Try including a clear source of protein (like eggs, yogurt, tofu, beans, fish, or lean meat) at each main meal.".localized(),
                    tag: .body
                ))
            }
            
            // Too much protein
            let muchProteinCount = proteinDays.filter { proteinDay in
                proteinDay.0 > UserData.shared.goalProtein * UpperScaling.protein &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: proteinDay.1) }?.0 ?? 0) != 0
            }.count
            if muchProteinCount >= 3 {
                suggestions.append(SuggestionsData(
                    id: "protein.much",
                    title: "Protein exceeded",
                    icon: UIImage(systemName: "bolt.fill"),
                    description: "In the past 10 days, you exceeded your protein goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchProteinCount)"),
                    color: .systemRed,
                    graph: proteinDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalProtein * UpperScaling.protein,
                        y: UserData.shared.goalProtein * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.9 * Double(muchProteinCount),
                    answer: "Very high protein can crowd out other important foods and may cause digestion issues for some people. Keep your protein, but make room on your plate for plenty of vegetables, fruit, and whole grains instead of relying mostly on shakes or large meat portions.".localized(),
                    tag: .body
                ))
            }
            
            // Too little fat
            let littleFatCount = fatDays.filter { fatDay in
                fatDay.0 < UserData.shared.goalFat * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: fatDay.1) }?.0 ?? 0) != 0
            }.count
            if littleFatCount >= 3 {
                suggestions.append(SuggestionsData(
                    id: "fat.little",
                    title: "Fat not reached",
                    icon: UIImage(systemName: "drop.fill"),
                    description: "In the past 10 days, you didn't reach your fat goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleFatCount)"),
                    color: .systemGreen,
                    graph: fatDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalFat * UpperScaling.fat,
                        y: UserData.shared.goalFat * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.8 * Double(littleFatCount),
                    answer: "Very low fat intake can make meals less satisfying and may affect how your body absorbs some vitamins. Add small amounts of healthy fats like olive oil, nuts, seeds, avocado, or fatty fish to help you feel fuller and support overall health.".localized(),
                    tag: .body
                ))
            }
            
            // Too much fat
            let muchFatCount = fatDays.filter { fatDay in
                fatDay.0 > UserData.shared.goalFat * UpperScaling.fat &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: fatDay.1) }?.0 ?? 0) != 0
            }.count
            if muchFatCount >= 3 {
                suggestions.append(SuggestionsData(
                    id: "fat.much",
                    title: "Fat exceeded",
                    icon: UIImage(systemName: "drop.fill"),
                    description: "In the past 10 days, you exceeded your fat goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchFatCount)"),
                    color: .systemOrange,
                    graph: fatDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalFat * UpperScaling.fat,
                        y: UserData.shared.goalFat * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.8 * Double(muchFatCount),
                    answer: "Fat is calorie-dense, so regularly eating more than your goal can make it easier to gain weight and feel heavy after meals, especially if it comes from fried or creamy foods. Try using a little less oil when cooking, choose leaner cuts of meat, and balance richer foods with vegetables and whole grains.".localized(),
                    tag: .body
                ))
            }
            
            // Too little fiber
            let littleFiberCount = fiberDays.filter { fiberDay in
                fiberDay.0 < UserData.shared.goalFiber * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: fiberDay.1) }?.0 ?? 0) != 0
            }.count
            if littleFiberCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "fiber.little",
                    title: "Fiber not reached",
                    icon: UIImage(systemName: "leaf.fill"),
                    description: "In the past 10 days, you didn't reach your fiber goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleFiberCount)"),
                    color: .systemGreen,
                    graph: fiberDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalFiber * UpperScaling.fiber,
                        y: UserData.shared.goalFiber * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.6 * Double(littleFiberCount),
                    answer: "Low fiber can contribute to constipation, less stable blood sugar, and feeling less full after meals. Slowly add more fruits, vegetables, whole grains, beans, and lentils, and drink enough water to support comfortable digestion.".localized(),
                    tag: .body
                ))
            }
            
            // Too much fiber
            let muchFiberCount = fiberDays.filter { fiberDay in
                fiberDay.0 > UserData.shared.goalFiber * UpperScaling.fiber &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: fiberDay.1) }?.0 ?? 0) != 0
            }.count
            if muchFiberCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "fiber.much",
                    title: "Fiber exceeded",
                    icon: UIImage(systemName: "leaf.fill"),
                    description: "In the past 10 days, you exceeded your fiber goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchFiberCount)"),
                    color: .systemBlue,
                    graph: fiberDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalFiber * UpperScaling.fiber,
                        y: UserData.shared.goalFiber * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.6 * Double(muchFiberCount),
                    answer: "Very high fiber, especially added quickly, can cause bloating, gas, or stomach discomfort. Try spreading high-fiber foods more evenly through the day and make sure you’re drinking enough water.".localized(),
                    tag: .body
                ))
            }
            
            // Too little sugar
            let littleSugarCount = sugarDays.filter { sugarDay in
                sugarDay.0 < UserData.shared.goalSugar * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: sugarDay.1) }?.0 ?? 0) != 0
            }.count
            if littleSugarCount >= 2 {
                suggestions.append(SuggestionsData(
                    id: "sugar.little",
                    title: "Sugar not reached",
                    icon: UIImage(systemName: "cube.fill"),
                    description: "In the past 10 days, you didn't reach your sugar goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleSugarCount)"),
                    color: .systemBlue,
                    graph: sugarDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalSugar * UpperScaling.sugar,
                        y: UserData.shared.goalSugar * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.5 * Double(littleSugarCount),
                    answer: "Keeping added sugar lower most days can help with more stable energy and long-term health. If you feel too restricted, you can still enjoy small, mindful portions of sweets or choose naturally sweet foods like fruit to satisfy cravings.".localized(),
                    tag: .body
                ))
            }
            
            // Too much sugar
            let muchSugarCount = sugarDays.filter { sugarDay in
                sugarDay.0 > UserData.shared.goalSugar * UpperScaling.sugar &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: sugarDay.1) }?.0 ?? 0) != 0
            }.count
            if muchSugarCount >= 2 {
                suggestions.append(SuggestionsData(
                    id: "sugar.much",
                    title: "Sugar exceeded",
                    icon: UIImage(systemName: "cube.fill"),
                    description: "In the past 10 days, you exceeded your sugar goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchSugarCount)"),
                    color: .systemRed,
                    graph: sugarDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalSugar * UpperScaling.sugar,
                        y: UserData.shared.goalSugar * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.5 * Double(muchSugarCount),
                    answer: "High sugar intake can lead to energy crashes, stronger cravings, and may contribute to weight gain and tooth issues over time. Try cutting back on sugary drinks and candies, and choose fruit, yogurt, or dark chocolate in smaller portions when you want something sweet.".localized(),
                    tag: .body
                ))
            }
            
            // Too little saturated fat
            let littleSaturatedFatCount = saturatedFatDays.filter { satFatDay in
                satFatDay.0 < UserData.shared.goalSaturatedFat * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: satFatDay.1) }?.0 ?? 0) != 0
            }.count
            if littleSaturatedFatCount >= 2 {
                suggestions.append(SuggestionsData(
                    id: "saturatedFat.little",
                    title: "Saturated Fat not reached",
                    icon: UIImage(systemName: "drop.triangle.fill"),
                    description: "In the past 10 days, you didn't reach your saturated fat goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleSaturatedFatCount)"),
                    color: .systemGreen,
                    graph: saturatedFatDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalSaturatedFat * UpperScaling.saturatedFat,
                        y: UserData.shared.goalSaturatedFat * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.6 * Double(littleSaturatedFatCount),
                    answer: "Keeping saturated fat on the lower side is generally helpful for heart health, so this is usually a good thing. There’s no need to add more on purpose unless a healthcare professional has advised you to.".localized(),
                    tag: .body
                ))
            }
            
            // Too much saturated fat
            let muchSaturatedFatCount = saturatedFatDays.filter { satFatDay in
                satFatDay.0 > UserData.shared.goalSaturatedFat * UpperScaling.saturatedFat &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: satFatDay.1) }?.0 ?? 0) != 0
            }.count
            if muchSaturatedFatCount >= 2 {
                suggestions.append(SuggestionsData(
                    id: "saturatedFat.much",
                    title: "Saturated Fat exceeded",
                    icon: UIImage(systemName: "drop.triangle.fill"),
                    description: "In the past 10 days, you exceeded your saturated fat goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchSaturatedFatCount)"),
                    color: .systemRed,
                    graph: saturatedFatDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalSaturatedFat * UpperScaling.saturatedFat,
                        y: UserData.shared.goalSaturatedFat * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.6 * Double(muchSaturatedFatCount),
                    answer: "A lot of saturated fat over time can raise LDL (“bad”) cholesterol in some people and increase heart-disease risk. Choose leaner meats, lower-fat dairy, and swap butter or cream-based sauces for olive oil or other plant oils more often.".localized(),
                    tag: .body
                ))
            }
            
            // Too little monounsaturated fat
            let littleMonounsaturatedFatCount = monounsaturatedFatDays.filter { monoFatDay in
                monoFatDay.0 < UserData.shared.goalMonosaturatedFat * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: monoFatDay.1) }?.0 ?? 0) != 0
            }.count
            if littleMonounsaturatedFatCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "monounsaturatedFat.little",
                    title: "Monounsaturated Fat not reached",
                    icon: UIImage(systemName: "drop.circle.fill"),
                    description: "In the past 10 days, you didn't reach your monounsaturated fat goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleMonounsaturatedFatCount)"),
                    color: .systemGreen,
                    graph: monounsaturatedFatDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalMonosaturatedFat * UpperScaling.monounsaturatedFat,
                        y: UserData.shared.goalMonosaturatedFat * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.4 * Double(littleMonounsaturatedFatCount),
                    answer: "Monounsaturated fats are the heart-friendlier fats and can support healthy cholesterol levels. Try adding a little olive oil on salads, a handful of nuts, or some avocado to your meals.".localized(),
                    tag: .body
                ))
            }
            
            // Too much monounsaturated fat
            let muchMonounsaturatedFatCount = monounsaturatedFatDays.filter { monoFatDay in
                monoFatDay.0 > UserData.shared.goalMonosaturatedFat * UpperScaling.monounsaturatedFat &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: monoFatDay.1) }?.0 ?? 0) != 0
            }.count
            if muchMonounsaturatedFatCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "monounsaturatedFat.much",
                    title: "Monounsaturated Fat exceeded",
                    icon: UIImage(systemName: "drop.circle.fill"),
                    description: "In the past 10 days, you exceeded your monounsaturated fat goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchMonounsaturatedFatCount)"),
                    color: .systemRed,
                    graph: monounsaturatedFatDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalMonosaturatedFat * UpperScaling.monounsaturatedFat,
                        y: UserData.shared.goalMonosaturatedFat * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.4 * Double(muchMonounsaturatedFatCount),
                    answer: "Even healthy fats are very calorie-dense, so large amounts can still slow weight loss or lead to weight gain. If needed, use a bit less oil when cooking and keep nut portions to a small handful at a time.".localized(),
                    tag: .body
                ))
            }
            
            // Too little cholesterol
            let littleCholesterolCount = cholesterolDays.filter { cholDay in
                cholDay.0 < UserData.shared.goalCholesterol * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: cholDay.1) }?.0 ?? 0) != 0
            }.count
            if littleCholesterolCount >= 2 {
                suggestions.append(SuggestionsData(
                    id: "cholesterol.little",
                    title: "Cholesterol not reached",
                    icon: UIImage(systemName: "heart.fill"),
                    description: "In the past 10 days, you didn't reach your cholesterol goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleCholesterolCount)"),
                    color: .systemGreen,
                    graph: cholesterolDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalCholesterol * UpperScaling.cholesterol,
                        y: UserData.shared.goalCholesterol * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.3 * Double(littleCholesterolCount),
                    answer: "Dietary cholesterol isn’t essential for most people, and keeping it lower can support heart health—especially if your doctor has advised it. As long as your overall diet is varied and balanced, you usually don’t need to increase cholesterol on purpose.".localized(),
                    tag: .body
                ))
            }
            
            // Too much cholesterol
            let muchCholesterolCount = cholesterolDays.filter { cholDay in
                cholDay.0 > UserData.shared.goalCholesterol * UpperScaling.cholesterol &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: cholDay.1) }?.0 ?? 0) != 0
            }.count
            if muchCholesterolCount >= 2 {
                suggestions.append(SuggestionsData(
                    id: "cholesterol.much",
                    title: "Cholesterol exceeded",
                    icon: UIImage(systemName: "heart.fill"),
                    description: "In the past 10 days, you exceeded your cholesterol goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchCholesterolCount)"),
                    color: .systemRed,
                    graph: cholesterolDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalCholesterol * UpperScaling.cholesterol,
                        y: UserData.shared.goalCholesterol * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.3 * Double(muchCholesterolCount),
                    answer: "High dietary cholesterol, especially together with lots of saturated fat, can raise blood cholesterol levels in some people. Try eating egg yolks, organ meats, and high-fat dairy a bit less often and focusing more on fish, beans, and plant-based meals. If you already have heart or cholesterol concerns, follow your doctor’s advice.".localized(),
                    tag: .body
                ))
            }
            
            // Too little sodium
            let littleSodiumCount = sodiumDays.filter { sodiumDay in
                sodiumDay.0 < UserData.shared.goalSodium * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: sodiumDay.1) }?.0 ?? 0) != 0
            }.count
            if littleSodiumCount >= 2 {
                suggestions.append(SuggestionsData(
                    id: "sodium.little",
                    title: "Sodium not reached",
                    icon: UIImage(systemName: "seal.fill"),
                    description: "In the past 10 days, you didn't reach your sodium goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleSodiumCount)"),
                    color: .systemBlue,
                    graph: sodiumDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalSodium * UpperScaling.sodium,
                        y: UserData.shared.goalSodium * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.4 * Double(littleSodiumCount),
                    answer: "Most people naturally get enough sodium from regular foods, and keeping it on the lower side can support healthy blood pressure. Unless a doctor has asked you to increase salt—for example because of certain medical conditions—there’s usually no need to add extra.".localized(),
                    tag: .body
                ))
            }
            
            // Too much sodium
            let muchSodiumCount = sodiumDays.filter { sodiumDay in
                sodiumDay.0 > UserData.shared.goalSodium * UpperScaling.sodium &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: sodiumDay.1) }?.0 ?? 0) != 0
            }.count
            if muchSodiumCount >= 2 {
                suggestions.append(SuggestionsData(
                    id: "sodium.much",
                    title: "Sodium exceeded",
                    icon: UIImage(systemName: "seal.fill"),
                    description: "In the past 10 days, you exceeded your sodium goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchSodiumCount)"),
                    color: .systemOrange,
                    graph: sodiumDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalSodium * UpperScaling.sodium,
                        y: UserData.shared.goalSodium * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.4 * Double(muchSodiumCount),
                    answer: "High sodium intake can cause water retention and, over time, may raise blood pressure for many people. To cut back, choose fewer salty snacks and instant foods, rinse canned foods where possible, taste before adding salt, and use herbs, spices, or lemon juice for flavor instead.".localized(),
                    tag: .body
                ))
            }
            
            // Too little potassium
            let littlePotassiumCount = potassiumDays.filter { potassiumDay in
                potassiumDay.0 < UserData.shared.goalPotassium * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: potassiumDay.1) }?.0 ?? 0) != 0
            }.count
            if littlePotassiumCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "potassium.little",
                    title: "Potassium not reached",
                    icon: UIImage(systemName: "bolt.circle.fill"),
                    description: "In the past 10 days, you didn't reach your potassium goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littlePotassiumCount)"),
                    color: .systemBlue,
                    graph: potassiumDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalPotassium * UpperScaling.potassium,
                        y: UserData.shared.goalPotassium * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.5 * Double(littlePotassiumCount),
                    answer: "Potassium helps your muscles and nervous system work properly and can balance the effects of sodium on blood pressure. Add more potassium-rich foods like bananas, potatoes, beans, and leafy greens—unless your doctor has given you limits because of kidney or heart issues.".localized(),
                    tag: .body
                ))
            }
            
            // Too much potassium
            let muchPotassiumCount = potassiumDays.filter { potassiumDay in
                potassiumDay.0 > UserData.shared.goalPotassium * UpperScaling.potassium &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: potassiumDay.1) }?.0 ?? 0) != 0
            }.count
            if muchPotassiumCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "potassium.much",
                    title: "Potassium exceeded",
                    icon: UIImage(systemName: "bolt.circle.fill"),
                    description: "In the past 10 days, you exceeded your potassium goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchPotassiumCount)"),
                    color: .systemPurple,
                    graph: potassiumDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalPotassium * UpperScaling.potassium,
                        y: UserData.shared.goalPotassium * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.5 * Double(muchPotassiumCount),
                    answer: "For most people with healthy kidneys, extra potassium from food isn’t a big issue, but very high intakes can be risky if you have kidney or heart problems or take certain medications. If that applies to you, talk with your doctor and consider easing back on top sources like bananas, potatoes, and large amounts of juices.".localized(),
                    tag: .body
                ))
            }
            
            // Too little vitamin A
            let littleVitaminACount = vitaminADays.filter { vitADay in
                vitADay.0 < UserData.shared.goalVitaminA * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: vitADay.1) }?.0 ?? 0) != 0
            }.count
            if littleVitaminACount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "vitaminA.little",
                    title: "Vitamin A not reached",
                    icon: UIImage(systemName: "eye.fill"),
                    description: "In the past 10 days, you didn't reach your vitamin A goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleVitaminACount)"),
                    color: .systemBlue,
                    graph: vitaminADays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalVitaminA * UpperScaling.vitaminA,
                        y: UserData.shared.goalVitaminA * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.3 * Double(littleVitaminACount),
                    answer: "Vitamin A supports vision, skin, and immune function, and regularly getting too little may not be ideal in the long run. Include more orange and dark-green vegetables like carrots, sweet potatoes, pumpkin, and spinach to help you get closer to your goal.".localized(),
                    tag: .body
                ))
            }
            
            // Too much vitamin A
            let muchVitaminACount = vitaminADays.filter { vitADay in
                vitADay.0 > UserData.shared.goalVitaminA * UpperScaling.vitaminA &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: vitADay.1) }?.0 ?? 0) != 0
            }.count
            if muchVitaminACount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "vitaminA.much",
                    title: "Vitamin A exceeded",
                    icon: UIImage(systemName: "eye.fill"),
                    description: "In the past 10 days, you exceeded your vitamin A goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchVitaminACount)"),
                    color: .systemGreen,
                    graph: vitaminADays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalVitaminA * UpperScaling.vitaminA,
                        y: UserData.shared.goalVitaminA * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.3 * Double(muchVitaminACount),
                    answer: "Very high vitamin A intake for long periods, especially from supplements or liver, can be harmful to the liver and bones. If you’re using high-dose vitamin A supplements or eating liver often, consider cutting back and getting more of your vitamin A from regular vegetables instead.".localized(),
                    tag: .body
                ))
            }
            
            // Too little vitamin C
            let littleVitaminCCount = vitaminCDays.filter { vitCDay in
                vitCDay.0 < UserData.shared.goalVitaminC * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: vitCDay.1) }?.0 ?? 0) != 0
            }.count
            if littleVitaminCCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "vitaminC.little",
                    title: "Vitamin C not reached",
                    icon: UIImage(systemName: "drop.fill"),
                    description: "In the past 10 days, you didn't reach your vitamin C goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleVitaminCCount)"),
                    color: .systemBlue,
                    graph: vitaminCDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalVitaminC * UpperScaling.vitaminC,
                        y: UserData.shared.goalVitaminC * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.3 * Double(littleVitaminCCount),
                    answer: "Vitamin C supports immune function and helps your body absorb iron, and low intake over time isn’t ideal. Try adding at least one portion of vitamin-C-rich foods daily, like citrus fruits, berries, kiwi, peppers, or broccoli.".localized(),
                    tag: .body
                ))
            }
            
            // Too much vitamin C
            let muchVitaminCCount = vitaminCDays.filter { vitCDay in
                vitCDay.0 > UserData.shared.goalVitaminC * UpperScaling.vitaminC &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: vitCDay.1) }?.0 ?? 0) != 0
            }.count
            if muchVitaminCCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "vitaminC.much",
                    title: "Vitamin C exceeded",
                    icon: UIImage(systemName: "drop.fill"),
                    description: "In the past 10 days, you exceeded your vitamin C goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchVitaminCCount)"),
                    color: .systemOrange,
                    graph: vitaminCDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalVitaminC * UpperScaling.vitaminC,
                        y: UserData.shared.goalVitaminC * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.3 * Double(muchVitaminCCount),
                    answer: "Extra vitamin C from normal foods is usually fine, but very high supplement doses can cause stomach upset or diarrhea in some people. If that’s happening, consider lowering your supplement dose and relying more on food sources instead.".localized(),
                    tag: .body
                ))
            }
            
            // Too little calcium
            let littleCalciumCount = calciumDays.filter { calciumDay in
                calciumDay.0 < UserData.shared.goalCalcium * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: calciumDay.1) }?.0 ?? 0) != 0
            }.count
            if littleCalciumCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "calcium.little",
                    title: "Calcium not reached",
                    icon: UIImage(systemName: "circle.grid.cross.fill"),
                    description: "In the past 10 days, you didn't reach your calcium goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleCalciumCount)"),
                    color: .systemPurple,
                    graph: calciumDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalCalcium * UpperScaling.calcium,
                        y: UserData.shared.goalCalcium * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.6 * Double(littleCalciumCount),
                    answer: "Calcium is important for bones and teeth, and getting too little over time can make it harder to keep them strong. Include more calcium-rich foods like milk, yogurt, cheese, calcium-fortified plant milks, tofu set with calcium, or leafy greens in your routine.".localized(),
                    tag: .body
                ))
            }
            
            // Too much calcium
            let muchCalciumCount = calciumDays.filter { calciumDay in
                calciumDay.0 > UserData.shared.goalCalcium * UpperScaling.calcium &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: calciumDay.1) }?.0 ?? 0) != 0
            }.count
            if muchCalciumCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "calcium.much",
                    title: "Calcium exceeded",
                    icon: UIImage(systemName: "circle.grid.cross.fill"),
                    description: "In the past 10 days, you exceeded your calcium goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchCalciumCount)"),
                    color: .systemBlue,
                    graph: calciumDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalCalcium * UpperScaling.calcium,
                        y: UserData.shared.goalCalcium * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.6 * Double(muchCalciumCount),
                    answer: "Very high calcium intake, especially from supplements, can increase the risk of kidney stones and may not give extra bone benefits. If you’re routinely above your goal, consider lowering supplement doses and relying more on food-based calcium unless your doctor advised otherwise.".localized(),
                    tag: .body
                ))
            }
            
            // Too little iron
            let littleIronCount = ironDays.filter { ironDay in
                ironDay.0 < UserData.shared.goalIron * 0.9 &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: ironDay.1) }?.0 ?? 0) != 0
            }.count
            if littleIronCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "iron.little",
                    title: "Iron not reached",
                    icon: UIImage(systemName: "bolt.heart.fill"),
                    description: "In the past 10 days, you didn't reach your iron goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(littleIronCount)"),
                    color: .systemOrange,
                    graph: ironDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalIron * UpperScaling.iron,
                        y: UserData.shared.goalIron * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.6 * Double(littleIronCount),
                    answer: "Low iron intake over time can contribute to tiredness, shortness of breath, and difficulty concentrating, especially in people who menstruate. Add more iron-rich foods like red meat, beans, lentils, tofu, spinach, or fortified cereals, and pair plant-based sources with vitamin-C-rich foods to help absorption.".localized(),
                    tag: .body
                ))
            }
            
            // Too much iron
            let muchIronCount = ironDays.filter { ironDay in
                ironDay.0 > UserData.shared.goalIron * UpperScaling.iron &&
                (caloriesDays.first { Calendar.current.isDate($0.1, inSameDayAs: ironDay.1) }?.0 ?? 0) != 0
            }.count
            if muchIronCount >= 4 {
                suggestions.append(SuggestionsData(
                    id: "iron.much",
                    title: "Iron exceeded",
                    icon: UIImage(systemName: "bolt.heart.fill"),
                    description: "In the past 10 days, you exceeded your iron goal _COUNT_ times.".localized().replacingOccurrences(of: "_COUNT_", with: "\(muchIronCount)"),
                    color: .systemRed,
                    graph: ironDays.sorted(by: { $0.1 < $1.1 }).map { day in
                        GraphVC.GraphData(x: day.1, y: day.0)
                    },
                    safeArea: CGPoint(
                        x: UserData.shared.goalIron * UpperScaling.iron,
                        y: UserData.shared.goalIron * 0.9
                    ),
                    isPresentingTime: false,
                    importance: 0.6 * Double(muchIronCount),
                    answer: "Excess iron, especially from supplements, can build up in the body and be harmful for some people, particularly those with certain genetic conditions. Avoid high-dose iron supplements unless prescribed and balance red meat with other protein sources; if you’re worried about iron, talk with your doctor about a blood test.".localized(),
                    tag: .body
                ))
            }
            
            completion(Array(suggestions.sorted(by: {
                if $0.title == $1.title {
                    return $0.importance > $1.importance
                } else {
                    return $0.title < $1.title
                }
            }).prefix(10)))
        }
    }
}
