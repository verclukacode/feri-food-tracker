//
//  EditFoodLogViewController.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 3. 1. 26.
//

import UIKit
import CoreData

final class EditFoodLogViewController: UIViewController, UITextViewDelegate {

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

    // MARK: - Core Data
    private let log: FoodLogData
    private let context: NSManagedObjectContext

    // MARK: - Completion
    private var completion: (() -> Void)?

    // MARK: - “Baseline” (per 100g) derived from existing log
    private var caloriesPer100g: Double = 0
    private var carbsPer100g: Double = 0
    private var proteinPer100g: Double = 0
    private var fatPer100g: Double = 0

    private var servingUnit: ServingUnit = .grams

    // MARK: - UI
    private let backScroll = UIScrollView()

    private let titleTextView = UITextView()
    private let servingUnitInput = LogFoodViewController.InputCellView(title: "Unit")
    private let servingSizeInput = LogFoodViewController.InputCellView(title: "Serving size")
    private let servingNumberInput = LogFoodViewController.InputCellView(title: "Number of servings")
    private let mealInput = LogFoodViewController.InputCellView(title: "Meal")

    private let dateInput = LogFoodViewController.InputCellView(title: "Date")
    private let dateInputPicker = UIDatePicker()

    private let actionButton = UIButton()

    // MARK: - Init
    init(log: FoodLogData, completion: (() -> Void)? = nil) {
        self.log = log
        self.context = log.managedObjectContext ?? NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(onClose)
        )

        navigationItem.titleView = {
            let label = UILabel()
            label.text = "Details"
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.textColor = .label
            label.sizeToFit()
            return label
        }()

        view.backgroundColor = .systemBackground
        view.addSubview(backScroll)

        setupUI()
        hydrateFromLog()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        backScroll.frame = view.bounds
        let maxWidth = view.bounds.width - 30

        titleTextView.frame = CGRect(
            x: 15,
            y: 30,
            width: maxWidth,
            height: titleTextView.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude)).height
        )

        servingUnitInput.frame = CGRect(x: 15, y: titleTextView.frame.maxY + 30, width: maxWidth, height: 50)
        servingUnitInput.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        servingSizeInput.frame = CGRect(x: 15, y: servingUnitInput.frame.maxY, width: maxWidth, height: 50)
        servingSizeInput.layer.maskedCorners = []

        servingNumberInput.frame = CGRect(x: 15, y: servingSizeInput.frame.maxY, width: maxWidth, height: 50)
        servingNumberInput.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        mealInput.frame = CGRect(x: 15, y: servingNumberInput.frame.maxY + 10, width: maxWidth, height: 50)
        dateInput.frame = CGRect(x: 15, y: mealInput.frame.maxY + 10, width: maxWidth, height: 50)

        dateInputPicker.frame = CGRect(x: dateInput.frame.width - 165, y: 0, width: 159, height: dateInput.frame.height)

        backScroll.contentSize = CGSize(width: view.frame.width, height: dateInput.frame.maxY)
        backScroll.contentInset.bottom = 260 + view.safeAreaInsets.bottom

        actionButton.frame = CGRect(
            x: (view.frame.width - 175) / 2,
            y: view.frame.height - view.safeAreaInsets.bottom - 80,
            width: 175,
            height: 50
        )
    }

    // MARK: - Setup UI
    private func setupUI() {
        titleTextView.textAlignment = .left
        titleTextView.textColor = .label
        titleTextView.backgroundColor = .clear
        titleTextView.isScrollEnabled = false
        titleTextView.textContainerInset = .zero
        titleTextView.textContainer.lineFragmentPadding = 0
        titleTextView.font = .systemFont(ofSize: 24, weight: .bold)
        titleTextView.delegate = self
        backScroll.addSubview(titleTextView)

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .prominent, target: self, action: #selector(doneEditingTitle))
        ]
        titleTextView.inputAccessoryView = toolbar

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        backScroll.addGestureRecognizer(tap)

        setupServingUnitMenu()
        servingUnitInput.showsMenuAsPrimaryAction = true
        backScroll.addSubview(servingUnitInput)

        servingSizeInput.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(title: "Serving size (\(self.servingUnit.displayName))", message: nil, preferredStyle: .alert)
            alert.addTextField { field in
                field.text = self.servingSizeInput.value
                field.keyboardType = .decimalPad
            }
            alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
                if let t = alert.textFields?.first?.text, !t.isEmpty {
                    self.servingSizeInput.value = t
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        backScroll.addSubview(servingSizeInput)

        servingNumberInput.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(title: self.servingNumberInput.titleView.text, message: nil, preferredStyle: .alert)
            alert.addTextField { field in
                field.text = self.servingNumberInput.value
                field.keyboardType = .decimalPad
            }
            alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
                if let t = alert.textFields?.first?.text, !t.isEmpty {
                    self.servingNumberInput.value = t
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        backScroll.addSubview(servingNumberInput)

        setupMealMenu()
        mealInput.showsMenuAsPrimaryAction = true
        backScroll.addSubview(mealInput)

        backScroll.addSubview(dateInput)
        dateInputPicker.contentHorizontalAlignment = .right
        dateInputPicker.datePickerMode = .date
        dateInput.addSubview(dateInputPicker)

        actionButton.backgroundColor = .systemBlue
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.cornerRadius = 25
        actionButton.layer.cornerCurve = .continuous
        actionButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        actionButton.setTitle("Save", for: .normal)

        actionButton.addAction(UIAction { [weak self] _ in
            self?.saveToCoreData()
        }, for: .touchUpInside)

        view.addSubview(actionButton)
    }

    private func setupServingUnitMenu() {
        servingUnitInput.value = servingUnit.displayName
        servingSizeInput.titleView.text = "Serving size (\(servingUnit.displayName))"

        servingUnitInput.menu = UIMenu(children: ServingUnit.allCases.map { unit in
            UIAction(title: unit.displayName, image: self.servingUnit == unit ? UIImage(systemName: "checkmark") : nil) { _ in
                guard self.servingUnit != unit else { return }
                self.servingUnit = unit
                self.servingUnitInput.value = unit.displayName
                self.servingSizeInput.titleView.text = "Serving size (\(unit.displayName))"
                self.setupServingUnitMenu()
            }
        })
    }

    private func setupMealMenu() {
        mealInput.menu = UIMenu(children: MealType.allCases.map { type in
            UIAction(title: type.rawValue, image: self.mealInput.value == type.rawValue ? UIImage(systemName: "checkmark") : nil) { _ in
                self.mealInput.value = type.rawValue
                self.setupMealMenu()
            }
        })
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }

    // MARK: - Hydrate from CoreData
    private func hydrateFromLog() {
        titleTextView.text = log.name
        mealInput.value = log.meal.rawValue

        dateInputPicker.date = log.date

        // Derive per-100g baseline from existing stored portion
        let grams = max(1.0, log.portionInGrams)
        let scaleTo100 = 100.0 / grams

        caloriesPer100g = log.calories * scaleTo100
        carbsPer100g = log.carbs * scaleTo100
        proteinPer100g = log.protein * scaleTo100
        fatPer100g = log.fat * scaleTo100

        // Default editing inputs (simple)
        servingUnit = .grams
        servingUnitInput.value = servingUnit.displayName
        servingSizeInput.value = String(log.portionInGrams)
        servingNumberInput.value = "1"
        servingSizeInput.titleView.text = "Serving size (\(servingUnit.displayName))"

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Save changes (Core Data → CloudKit sync happens automatically)
    private func saveToCoreData() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let gramsPerServing = (Double(servingSizeInput.value.replacingOccurrences(of: ",", with: ".")) ?? 0) * servingUnit.multiplicator
        let servings = Double(servingNumberInput.value.replacingOccurrences(of: ",", with: ".")) ?? 1
        let portion = max(0, gramsPerServing * servings)

        func perPortion(_ per100g: Double) -> Double {
            (per100g / 100.0) * portion
        }

        let newName = titleTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let meal = MealType(rawValue: mealInput.value) ?? .breakfast
        let date = dateInputPicker.date

        log.name = newName.isEmpty ? log.name : newName
        log.meal = meal
        log.date = date
        log.portionInGrams = portion

        log.calories = perPortion(caloriesPer100g)
        log.carbs = perPortion(carbsPer100g)
        log.protein = perPortion(proteinPer100g)
        log.fat = perPortion(fatPer100g)

        // If you want to keep the other nutrients consistent too, update them here similarly.

        do {
            try context.save()
            actionButton.setTitle("Saved", for: .normal)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIAccessibility.post(notification: .announcement, argument: "Saved.")
            dismiss(animated: true) { self.completion?() }
        } catch {
            print("CoreData save failed:", error)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            UIAccessibility.post(notification: .announcement, argument: "Save failed.")
        }
    }

    @objc private func doneEditingTitle() {
        titleTextView.resignFirstResponder()
    }

    @objc override internal func onClose() {
        completion?()
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
