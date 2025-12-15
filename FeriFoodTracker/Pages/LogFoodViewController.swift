//
//  LogFoodViewController.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 1. 10. 25.
//

import UIKit
import StoreKit

class LogFoodViewController: UIViewController, UITextViewDelegate {
    
    enum ServingUnit: String, CaseIterable {
        case grams = "g"
        case tablespoon = "tbsp"
        case teaspoon = "tsp"
        case cup = "cup"
        case oz = "oz"
        case milliliter = "milliliter"

        var displayName: String {
            switch self {
            case .grams: return "Grams"
            case .tablespoon: return "Tablespoon"
            case .teaspoon: return "Teaspoon"
            case .cup: return "Cup"
            case .oz: return "Oz"
            case .milliliter: return "Milliliter"
            }
        }
        
        var multiplicator: Double {
            switch self {
            case .grams: return 1
            case .tablespoon: return 15
            case .teaspoon: return 5
            case .cup: return 240
            case .oz: return 28
            case .milliliter: return 1.1
            }
        }
    }

    
    //Data
    var isCreathingNewLog = false
    var completion: (()->())?
    var searchedFoodData: APIManager.FoodData?
    
    var caloriesPer100g: Double = 0
    var carbsPer100g: Double = 0
    var proteinPer100g: Double = 0
    var fatPer100g: Double = 0
    
    var servingUnit: ServingUnit = .grams
    
    convenience init(food: APIManager.FoodData, completion: (()->())? = nil) {
        self.init()
        self.completion = completion
        self.searchedFoodData = food
        
        self.isCreathingNewLog = true
        self.actionButton.setTitle("Log food", for: .normal)
        
        self.titleTextView.text = food.name.capitalized
        self.servingUnit = .grams
        self.servingSizeInput.value = String(food.defaultServingSize)
        self.servingNumberInput.value = String(1)
        self.mealInput.value = UserData.shared.selectedMeal.rawValue
        
        self.carbsPer100g = food.amount(of: .carbsG, for: 100) ?? 0
        self.proteinPer100g = food.amount(of: .proteinG, for: 100) ?? 0
        self.fatPer100g = food.amount(of: .fatG, for: 100) ?? 10
        self.caloriesPer100g = food.calories(for: 100)
        
        self.calculateUI()
    }
    
    
    //UI
    let backScroll = UIScrollView()
    
    let titleTextView = UITextView()
    let servingUnitInput = InputCellView(title: "Unit")
    let servingSizeInput = InputCellView(title: "Serving size")
    let servingNumberInput = InputCellView(title: "Number of servings")
    let mealInput = InputCellView(title: "Meal")
    
    let dateInput = InputCellView(title: "Date")
    let dateInputPicker = UIDatePicker()
    
    let actionButton = UIButton()
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        backScroll.frame = view.bounds
        
        titleTextView.frame = CGRect(x: 15, y: 30, width: view.frame.width - 30, height: titleTextView.sizeThatFits(CGSize(width: view.frame.width - 30, height: .greatestFiniteMagnitude)).height)
        
        servingUnitInput.frame = CGRect(x: 15, y: titleTextView.frame.maxY + 30, width: view.frame.width - 30, height: 50)
        servingUnitInput.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        servingSizeInput.frame = CGRect(x: 15, y: servingUnitInput.frame.maxY, width: view.frame.width - 30, height: 50)
        servingSizeInput.layer.maskedCorners = []
        
        servingNumberInput.frame = CGRect(x: 15, y: servingSizeInput.frame.maxY, width: view.frame.width - 30, height: 50)
        servingNumberInput.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        mealInput.frame = CGRect(x: 15, y: servingNumberInput.frame.maxY + 10, width: view.frame.width - 30, height: 50)
        dateInput.frame = CGRect(x: 15, y: mealInput.frame.maxY + 10, width: view.frame.width - 30, height: 50)
        dateInputPicker.frame = CGRect(x: dateInput.frame.width - 165, y: 0, width: 159, height: dateInput.frame.height)
        
        backScroll.contentSize = CGSize(width: view.frame.width, height: dateInput.frame.maxY)
        backScroll.contentInset.bottom = 260 + view.safeAreaInsets.bottom
        
        actionButton.frame = CGRect(x: (view.frame.width - 175) / 2, y: view.frame.height - view.safeAreaInsets.bottom - 80, width: 175, height: 50)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Announce screen change for VoiceOver
        UIAccessibility.post(notification: .screenChanged, argument: self.navigationItem.titleView ?? self.view)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(onClose))
        
        self.navigationItem.titleView = {
            let label = UILabel()
            label.text = "Details"
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.textColor = .label
            label.sizeToFit()
            return label
        }()
        
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(backScroll)
        
        
        titleTextView.textAlignment = .left
        titleTextView.textColor = .label
        titleTextView.backgroundColor = .clear
        titleTextView.isScrollEnabled = false
        titleTextView.textContainerInset = .zero
        titleTextView.textContainer.lineFragmentPadding = 0
        titleTextView.font = .systemFont(ofSize: 24, weight: .bold)
        titleTextView.accessibilityLabel = "Food name"
        titleTextView.accessibilityHint = "Double tap to edit the food name."
        titleTextView.delegate = self

        // Add an accessory toolbar with Done button to dismiss keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .prominent, target: self, action: #selector(doneEditingTitle))
        toolbar.items = [flexible, done]
        self.titleTextView.inputAccessoryView = toolbar
        
        backScroll.addSubview(titleTextView)
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        backScroll.addGestureRecognizer(tap)
        
        servingUnitInput.value = self.servingUnit.displayName
        func setServingUnitInputMenu() {
            servingUnitInput.menu = UIMenu(children: ServingUnit.allCases.map({ unit in
                return UIAction(title: unit.displayName, image: self.servingUnit == unit ? UIImage(systemName: "checkmark") : nil) { _ in
                    
                    if self.servingUnit == unit {
                        return
                    }
                    
                    self.servingUnit = unit
                    self.servingUnitInput.value = unit.displayName
                    self.servingSizeInput.titleView.text = "Serving size (_UNIT_)".replacingOccurrences(of: "_UNIT_", with: unit.displayName)
                    self.calculateUI()
                    setServingUnitInputMenu()
                }
            }))
        }
        setServingUnitInputMenu()
        servingUnitInput.showsMenuAsPrimaryAction = true
        backScroll.addSubview(servingUnitInput)
        
        servingSizeInput.titleView.text = "Serving size (_UNIT_)".replacingOccurrences(of: "_UNIT_", with: self.servingUnit.displayName)
        servingSizeInput.addAction(UIAction(handler: { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            let alert = UIAlertController(title: "Serving size (\(self.servingUnit.displayName))", message: nil, preferredStyle: .alert)
            alert.addTextField { field in
                field.text = self.servingSizeInput.value
                field.placeholder = "Serving size"
                field.keyboardType = .decimalPad
            }
            alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
                if let text = alert.textFields?.first?.text, !text.isEmpty {
                    let value = Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
                    self.servingSizeInput.value = String(value)
                    self.calculateUI()
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
            
        }), for: .touchUpInside)
        backScroll.addSubview(servingSizeInput)
        
        
        servingNumberInput.addAction(UIAction(handler: { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            let alert = UIAlertController(title: self.servingNumberInput.titleView.text, message: nil, preferredStyle: .alert)
            alert.addTextField { field in
                field.text = self.servingNumberInput.value
                field.placeholder = "Number of servings"
                field.keyboardType = .decimalPad
            }
            
            alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
                if let text = alert.textFields?.first?.text, !text.isEmpty {
                    let value = Double(text.replacingOccurrences(of: ",", with: ".")) ?? 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self.servingNumberInput.value = String(value)
                    self.calculateUI()
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            self.present(alert, animated: true)
            
        }), for: .touchUpInside)
        backScroll.addSubview(servingNumberInput)
        
        
        func setMealInputMenu() {
            mealInput.menu = UIMenu(children: MealType.allCases.map({ type in
                return UIAction(title: type.rawValue, image: UserData.shared.selectedMeal == type ? UIImage(systemName: "checkmark") : nil) { _ in
                    UserData.shared.selectedMeal = type
                    self.mealInput.value = type.rawValue
                    setMealInputMenu()
                }
            }))
        }
        setMealInputMenu()
        mealInput.showsMenuAsPrimaryAction = true
        backScroll.addSubview(mealInput)
        
        dateInput.value = ""
        backScroll.addSubview(dateInput)
        dateInputPicker.contentHorizontalAlignment = .right
        dateInputPicker.datePickerMode = .date
        dateInputPicker.date = ViewController.selectedDate
        dateInputPicker.addAction(UIAction(handler: { _ in
            ViewController.selectedDate = self.dateInputPicker.date
        }), for: .valueChanged)
        dateInput.addSubview(dateInputPicker)
        
        
        actionButton.backgroundColor = .label
        actionButton.setTitleColor(.systemBackground, for: .normal)
        actionButton.tintColor = .systemBackground
        actionButton.layer.cornerRadius = 25
        actionButton.layer.cornerCurve = .continuous
        actionButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        if #available(iOS 26.0, *) {
            actionButton.configuration = .prominentClearGlass()
        }
        actionButton.addAction(UIAction(handler: { _ in
            self.actionButton.setTitle("Logged", for: .normal)
            self.actionButton.accessibilityLabel = "Logged"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIAccessibility.post(notification: .announcement, argument: "Food logged.")
            if let data = self.searchedFoodData, self.isCreathingNewLog {
                let portion = (Double(self.servingSizeInput.value) ?? 1) * self.servingUnit.multiplicator * (Double(self.servingNumberInput.value) ?? 0)
                let meal = MealType(rawValue: self.mealInput.value) ?? .breakfast
                
                let _ = CloudManager.shared.newLog(name: data.name,
                                                   meal: meal,
                                                   calcium: (data.amount(of: .calciumMg, for: portion) ?? 0) / 1000,
                                                   calories: data.calories(for: portion),
                                                   carbs: data.amount(of: .carbsG, for: portion) ?? 0,
                                                   fat: data.amount(of: .fatG, for: portion) ?? 0,
                                                   cholesterol: (data.amount(of: .cholesterolMg, for: portion) ?? 0) / 1000,
                                                   fiber: data.amount(of: .fiberG, for: portion) ?? 0,
                                                   iron: (data.amount(of: .ironMg, for: portion) ?? 0) / 1000,
                                                   monosaturatedFat: data.amount(of: .monoFatG, for: portion) ?? 0,
                                                   polyunsaturatedFat: data.amount(of: .polyFatG, for: portion) ?? 0,
                                                   portionInGrams: portion,
                                                   potassium: (data.amount(of: .potassiumMg, for: portion) ?? 0) / 1000,
                                                   protein: data.amount(of: .proteinG, for: portion) ?? 0,
                                                   saturatedFat: data.amount(of: .satFatG, for: portion) ?? 0,
                                                   sodium: (data.amount(of: .sodiumMg, for: portion) ?? 0) / 1000,
                                                   sugar: data.amount(of: .sugarsG, for: portion) ?? 0,
                                                   vitaminA: (data.amount(of: .vitaminA_RAE_ug, for: portion) ?? 0) / 1_000_000,
                                                   vitaminC: (data.amount(of: .vitaminC_mg, for: portion) ?? 0) / 1000, date: ViewController.selectedDate)
                
                
                self.onClose()
            }
            
        }), for: .touchUpInside)
        view.addSubview(actionButton)
    }
    
    @objc
    func doneEditingTitle() {
        let newName = titleTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty {
            searchedFoodData?.name = newName
        }
        self.titleTextView.resignFirstResponder()
    }
    
    @objc
    func onClose() {
        if let navigationController = self.navigationController, navigationController.viewControllers.count > 1 {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    func calculateUI() {
        
        func convert(_ number: Double) -> Double {
            let grams = (Double(self.servingSizeInput.value) ?? 0) * self.servingUnit.multiplicator
            let step1 = (number / 100)
            let step2 = step1 * grams
            let step3 = step2 * (Double(self.servingNumberInput.value) ?? 0)
            return step3
        }
        
        let calories = convert(self.caloriesPer100g)
        let carbs = convert(self.carbsPer100g)
        let protein = convert(self.proteinPer100g)
        let fat = convert(self.fatPer100g)
        
        // Update servingSizeInput title to reflect the unit
        self.servingSizeInput.titleView.text = "Serving size (\(self.servingUnit.displayName))"
        
        
        self.viewDidLayoutSubviews()
    }
   
}


extension LogFoodViewController {
    
    struct FoodStructure {
        var name: String
        var servingSize: Double
        var meal: MealType
        
        var caloriesPer100g: Double
        
        var carbsPer100g: Double
        var proteinPer100g: Double
        var fatPer100g: Double
    }
    
}


extension LogFoodViewController {
    
    class InputCellView: UIButton {
        
        
        let titleView = UILabel()
        let valueView = UILabel()
        
        var value: String {
            set(newValue) {
                self.valueView.text = newValue
            } get {
                return self.valueView.text ?? ""
            }
        }
        
        convenience init(title: String) {
            self.init()
            self.titleView.text = title
        }
        
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.layer.cornerRadius = 20
            
            titleView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: self.frame.height)
            valueView.frame = titleView.frame
            
            // Accessibility label follows visible title + value
            var components: [String] = []
            if let t = titleView.text, !t.isEmpty { components.append(t) }
            if let v = valueView.text, !v.isEmpty { components.append(v) }
            self.accessibilityLabel = components.joined(separator: ", ")
        }
        
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.backgroundColor = .secondarySystemBackground
            self.layer.cornerCurve = .continuous
            
            titleView.text = "--"
            titleView.textAlignment = .left
            titleView.isUserInteractionEnabled = false
            titleView.textColor = .secondaryLabel
            titleView.font = .systemFont(ofSize: 17)
            self.addSubview(titleView)
            
            valueView.text = "--"
            valueView.textAlignment = .right
            valueView.isUserInteractionEnabled = false
            valueView.textColor = .systemBlue
            valueView.font = .systemFont(ofSize: 17, weight: .semibold)
            self.addSubview(valueView)
            
            // Accessibility
            isAccessibilityElement = true
            accessibilityTraits = [.button]
        }
        
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
    }
    
}


extension LogFoodViewController {
    func textViewDidChange(_ textView: UITextView) {
        guard textView === titleTextView else { return }
        let maxWidth = view.frame.width - 30
        let fittingSize = textView.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        var frame = textView.frame
        // Only update if height changed to avoid layout loops
        if abs(frame.height - fittingSize.height) > 0.5 {
            frame.size.height = fittingSize.height
            textView.frame = frame
            // Reposition dependent views by asking the view to layout again
            view.setNeedsLayout()
            view.layoutIfNeeded()
            // Also update scroll content size so it can scroll if needed
            backScroll.contentSize = CGSize(width: view.frame.width, height: dateInput.frame.maxY)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard textView === titleTextView else { return }
        let newName = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty {
            searchedFoodData?.name = newName
        }
    }
}
