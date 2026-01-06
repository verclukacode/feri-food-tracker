//
//  SettingsViewController.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 2. 10. 25.
//

import UIKit

class SettingsViewController: UIViewController {
    
    var completion: (()->())?
    convenience init(completion: (()->())?) {
        self.init()
        self.completion = completion
    }
    
    private let scrollView = UIScrollView()
    
    private let caloriesField = SettingsField(icon: UIImage(systemName: "flame.fill"), title: "Daily calories".localized())
    
    private let proteinField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Protein".localized())
    private let carbsField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Carbs".localized())
    private let fiberField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Fiber".localized())
    private let sugarField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Sugar".localized())
    private let fatField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Fat goal".localized())
    private let saturatedFatField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Saturated fat".localized())
    private let monosaturatedFatField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Monosaturated fat".localized())
    private let cholesterolField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Cholesterol".localized())
    private let sodiumField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Sodium".localized())
    private let potassiumField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Potassium".localized())
    private let vitaminAField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Vitamin A".localized())
    private let vitaminCField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Vitamic C".localized())
    private let calciumField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Calcium".localized())
    private let ironField = SettingsField(icon: UIImage(systemName: "fork.knife"), title: "Iron".localized())
    
    private let resetNutritionField = SettingsField(icon: UIImage(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90"), title: "Change diet".localized())
    
    private let otherField = SettingsField(icon: UIImage(systemName: "gear"), title: "System settings".localized())
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        caloriesField.frame = CGRect(x: 15, y: 15, width: view.frame.width - 30, height: 50)
        
        let fieldHeight: CGFloat = 50
        let fieldSpacing: CGFloat = 0
        let fieldWidth = view.frame.width - 30
        var y: CGFloat = caloriesField.frame.maxY + 30
        
        func place(_ field: UIView) {
            field.frame = CGRect(x: 15, y: y, width: fieldWidth, height: fieldHeight)
            y = field.frame.maxY + fieldSpacing
            field.layer.maskedCorners = []
        }
        
        place(proteinField)
        proteinField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        place(carbsField)
        place(fiberField)
        place(sugarField)
        place(fatField)
        place(saturatedFatField)
        place(monosaturatedFatField)
        place(cholesterolField)
        place(sodiumField)
        place(potassiumField)
        place(vitaminAField)
        place(vitaminCField)
        place(calciumField)
        place(ironField)
        ironField.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        resetNutritionField.frame = CGRect(x: 15, y: ironField.frame.maxY + 15, width: view.frame.width - 30, height: 50)
        
        otherField.frame = CGRect(x: 15, y: resetNutritionField.frame.maxY + 30, width: view.frame.width - 30, height: 50)
        
        scrollView.contentSize = CGSize(
            width: view.frame.width,
            height: max(otherField.frame.maxY,
                        view.frame.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
        )
        scrollView.contentInset.bottom = 30
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Background
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .prominent, target: self, action: #selector(onClose))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Save settings"
        navigationItem.rightBarButtonItem?.accessibilityHint = "Closes settings and saves your changes"
        
        // Accessibility: scrollView as container, not a single element
        scrollView.isAccessibilityElement = false
        
        caloriesField.accessibilityHint = "Change your daily calorie target".localized()
        caloriesField.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(title: "Change daily calories (kcal)".localized(), message: nil, preferredStyle: .alert)
            alert.addTextField { tf in
                tf.keyboardType = .numberPad
                tf.text = "\(Int(UserData.shared.goalCalories.rounded()))"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let newKcal = Double(t) {
                    // Keep current macro % and only recompute grams to the new kcal.
                    let p = self.currentMacroPercents()
                    UserData.shared.goalCalories = newKcal
                    self.setMacros(percentFat: p.fat, percentProtein: p.protein, percentCarbs: p.carbs)
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }), for: .touchUpInside)
        scrollView.addSubview(caloriesField)
        
        wireSettingsFields()
        
        resetNutritionField.menu = UIMenu(children: DietStyle.allCases.map({ type in
            return UIAction(title: type.rawValue.localized()) { _ in
                UserData.shared.setDefaults(forCalories: UserData.shared.goalCalories, style: type)
                self.refresh()
            }
        }))
        resetNutritionField.showsMenuAsPrimaryAction = true
        resetNutritionField.accessibilityHint = "Reset your nutrition goals to a predefined style".localized()
        scrollView.addSubview(resetNutritionField)
        
        otherField.addAction(UIAction(handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }), for: .touchUpInside)
        otherField.accessibilityHint = "Open the system settings for this app".localized()
        scrollView.addSubview(otherField)
        
        // Refresh
        refresh()
    }
    
    // Dismiss
    @objc
    override func onClose() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        completion?()
        dismiss(animated: true)
    }
    
    // Reload
    @objc
    public func refresh() {
        
        caloriesField.setValue(text: "\(Int(UserData.shared.goalCalories)) kcal", color: .systemBlue)
        
        // Macros as %
        let kcal = max(UserData.shared.goalCalories, 1)
        let fatPct     = Int((UserData.shared.goalFat * 9.0)  / kcal * 100.0)
        let proteinPct = Int((UserData.shared.goalProtein * 4.0) / kcal * 100.0)
        let carbsPct   = Int((UserData.shared.goalCarbs * 4.0)   / kcal * 100.0)
        
        proteinField.setValue(text: "\(proteinPct)%", color: .systemBlue)
        carbsField.setValue(text: "\(carbsPct)%", color: .systemBlue)
        fatField.setValue(text: "\(fatPct)%", color: .systemBlue)
        
        // Fiber & sugar in g
        fiberField.setValue(text: "\(Int(UserData.shared.goalFiber.rounded())) g", color: .systemBlue)
        sugarField.setValue(text: "\(Int(UserData.shared.goalSugar.rounded())) g", color: .systemBlue)
        
        // Fats in g
        saturatedFatField.setValue(text: "\(Int(UserData.shared.goalSaturatedFat.rounded())) g", color: .systemBlue)
        monosaturatedFatField.setValue(text: "\(Int(UserData.shared.goalMonosaturatedFat.rounded())) g", color: .systemBlue)
        
        // Cholesterol mg
        cholesterolField.setValue(text: "\(Int(UserData.shared.goalCholesterol * 1000)) mg", color: .systemBlue)
        
        // Sodium & Potassium mg
        sodiumField.setValue(text: "\(Int(UserData.shared.goalSodium * 1000)) mg", color: .systemBlue)
        potassiumField.setValue(text: "\(Int(UserData.shared.goalPotassium * 1000)) mg", color: .systemBlue)
        
        // Vitamins & minerals as % RDI
        let vitAPct     = Int((UserData.shared.goalVitaminA / 0.0009) * 100)
        let vitCPct     = Int((UserData.shared.goalVitaminC / 0.09) * 100)
        let calciumPct  = Int((UserData.shared.goalCalcium / 1.0) * 100)
        let ironPct     = Int((UserData.shared.goalIron / 0.018) * 100)
        
        vitaminAField.setValue(text: "\(vitAPct)%", color: .systemBlue)
        vitaminCField.setValue(text: "\(vitCPct)%", color: .systemBlue)
        calciumField.setValue(text: "\(calciumPct)%", color: .systemBlue)
        ironField.setValue(text: "\(ironPct)%", color: .systemBlue)
    }
    
    
    // MARK: - Data cell
    public class SettingsField: UIButton {
        
        private let iconView = UIImageView()
        private let titleView = UILabel()
        private let valueLabel = UILabel()
        
        convenience init(icon: UIImage?, title: String) {
            self.init()
            iconView.image = icon
            titleView.text = title
            accessibilityLabel = title
            accessibilityTraits = [.button]
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            layer.cornerRadius = 20
            layer.cornerCurve = .continuous
            
            iconView.frame = CGRect(x: 20, y: (frame.height - 22) / 2, width: 22, height: 22)
            titleView.frame = CGRect(
                x: iconView.frame.maxX + 10,
                y: 0,
                width: (frame.width - 82) / 4 * 3,
                height: frame.height
            )
            valueLabel.frame = CGRect(
                x: titleView.frame.maxX + 10,
                y: 0,
                width: (frame.width - 82) / 4,
                height: frame.height
            )
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .secondarySystemBackground
            
            isAccessibilityElement = true
            
            iconView.isUserInteractionEnabled = false
            iconView.tintColor = .label
            iconView.contentMode = .scaleAspectFit
            iconView.isAccessibilityElement = false
            addSubview(iconView)
            
            titleView.isUserInteractionEnabled = false
            titleView.textColor = .label
            titleView.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            titleView.textAlignment = .left
            titleView.adjustsFontSizeToFitWidth = true
            titleView.isAccessibilityElement = false
            addSubview(titleView)
            
            valueLabel.isUserInteractionEnabled = false
            valueLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            valueLabel.textAlignment = .right
            valueLabel.adjustsFontSizeToFitWidth = true
            valueLabel.isAccessibilityElement = false
            addSubview(valueLabel)
        }
        
        public func setValue(text: String, color: UIColor) {
            valueLabel.text = text
            valueLabel.textColor = color
            
            // Accessibility value includes both label and value
            if let labelText = titleView.text {
                accessibilityLabel = labelText
            }
            accessibilityValue = text
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    // MARK: - Helpers for macro % <-> grams
    
    private func currentMacroPercents() -> (fat: Double, protein: Double, carbs: Double) {
        let kcal = max(UserData.shared.goalCalories, 1)
        let fatPct     = (UserData.shared.goalFat * 9.0)  / kcal * 100.0
        let proteinPct = (UserData.shared.goalProtein * 4.0) / kcal * 100.0
        let carbsPct   = (UserData.shared.goalCarbs * 4.0)   / kcal * 100.0
        return (fatPct, proteinPct, carbsPct)
    }
    
    private func setMacros(percentFat: Double, percentProtein: Double, percentCarbs: Double) {
        let kcal = max(UserData.shared.goalCalories, 1)
        UserData.shared.goalFat     = (kcal * percentFat     / 100.0) / 9.0
        UserData.shared.goalProtein = (kcal * percentProtein / 100.0) / 4.0
        UserData.shared.goalCarbs   = (kcal * percentCarbs   / 100.0) / 4.0
    }
    
    // Rebalance two other macros proportionally to their current shares
    private func rebalanceMacros(changed: String, to newPercent: Double) {
        let p = currentMacroPercents()
        let clamped = max(0, min(newPercent, 100))
        let remainder = max(0, 100 - clamped)
        
        switch changed {
        case "fat":
            let sum = max(p.protein + p.carbs, 0.0001)
            _ = remainder * (p.protein / sum)
            _ = remainder * (p.carbs   / sum)
            setMacros(percentFat: clamped, percentProtein: p.protein, percentCarbs: p.carbs)
        case "protein":
            let sum = max(p.fat + p.carbs, 0.0001)
            _ = remainder * (p.fat   / sum)
            _ = remainder * (p.carbs / sum)
            setMacros(percentFat: p.fat, percentProtein: clamped, percentCarbs: p.carbs)
        case "carbs":
            let sum = max(p.fat + p.protein, 0.0001)
            _ = remainder * (p.fat     / sum)
            _ = remainder * (p.protein / sum)
            setMacros(percentFat: p.fat, percentProtein: p.protein, percentCarbs: clamped)
        default:
            break
        }
    }
    
    // MARK: - Reference intakes (stored in grams)
    private let RDI_Calcium_g:   Double = 1.0       // 1000 mg
    private let RDI_Iron_g:      Double = 0.018     // 18 mg
    private let RDI_VitA_g:      Double = 0.0009    // 900 µg
    private let RDI_VitC_g:      Double = 0.09      // 90 mg
    
    // MARK: - Attach actions (mirror of caloriesField)
    private func wireSettingsFields() {
        // Protein (% of calories)
        proteinField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change protein % of calories".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .decimalPad
                let pct = Int(round(self.currentMacroPercents().protein))
                tf.text = "\(pct)"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let pct = Double(t) {
                    self.rebalanceMacros(changed: "protein", to: pct)
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        proteinField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        proteinField.accessibilityHint = "Change the percentage of calories that should come from protein".localized()
        scrollView.addSubview(proteinField)
        
        // Carbs (% of calories)
        carbsField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change carbs % of calories".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .decimalPad
                let pct = Int(round(self.currentMacroPercents().carbs))
                tf.text = "\(pct)"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let pct = Double(t) {
                    self.rebalanceMacros(changed: "carbs", to: pct)
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        carbsField.accessibilityHint = "Change the percentage of calories that should come from carbohydrates".localized()
        scrollView.addSubview(carbsField)
        
        // Fat (% of calories)
        fatField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change fat % of calories".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .decimalPad
                let pct = Int(round(self.currentMacroPercents().fat))
                tf.text = "\(pct)"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let pct = Double(t) {
                    self.rebalanceMacros(changed: "fat", to: pct)
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        fatField.accessibilityHint = "Change the percentage of calories that should come from fat".localized()
        scrollView.addSubview(fatField)
        
        // Fiber (g)
        fiberField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change fiber (g)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .decimalPad
                tf.text = "\(Int(UserData.shared.goalFiber.rounded()))"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let g = Double(t) {
                    UserData.shared.goalFiber = g
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        fiberField.accessibilityHint = "Change your daily fiber goal in grams".localized()
        scrollView.addSubview(fiberField)
        
        // Sugar (g)
        sugarField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change sugar (g)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .decimalPad
                tf.text = "\(Int(UserData.shared.goalSugar.rounded()))"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let g = Double(t) {
                    UserData.shared.goalSugar = g
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        sugarField.accessibilityHint = "Change your daily sugar goal in grams".localized()
        scrollView.addSubview(sugarField)
        
        // Saturated fat (g)
        saturatedFatField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change saturated fat (g)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .decimalPad
                tf.text = "\(Int(UserData.shared.goalSaturatedFat.rounded()))"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let g = Double(t) {
                    UserData.shared.goalSaturatedFat = g
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        saturatedFatField.accessibilityHint = "Change your daily saturated fat goal in grams".localized()
        scrollView.addSubview(saturatedFatField)
        
        // Monosaturated fat (g)
        monosaturatedFatField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change monosaturated fat (g)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .decimalPad
                tf.text = "\(Int(UserData.shared.goalMonosaturatedFat.rounded()))"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let g = Double(t) {
                    UserData.shared.goalMonosaturatedFat = g
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        monosaturatedFatField.accessibilityHint = "Change your daily monosaturated fat goal in grams".localized()
        scrollView.addSubview(monosaturatedFatField)
        
        // Cholesterol (mg) -> store as grams
        cholesterolField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change cholesterol (mg)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .numberPad
                tf.text = "\(Int((UserData.shared.goalCholesterol * 1000).rounded()))"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let mg = Double(t) {
                    UserData.shared.goalCholesterol = mg / 1000.0
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        cholesterolField.accessibilityHint = "Change your daily cholesterol goal in milligrams".localized()
        scrollView.addSubview(cholesterolField)
        
        // Sodium (mg) -> grams
        sodiumField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change sodium (mg)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .numberPad
                tf.text = "\(Int((UserData.shared.goalSodium * 1000).rounded()))"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let mg = Double(t) {
                    UserData.shared.goalSodium = mg / 1000.0
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        sodiumField.accessibilityHint = "Change your daily sodium goal in milligrams".localized()
        scrollView.addSubview(sodiumField)
        
        // Potassium (mg) -> grams
        potassiumField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change potassium (mg)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .numberPad
                tf.text = "\(Int((UserData.shared.goalPotassium * 1000).rounded()))"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let mg = Double(t) {
                    UserData.shared.goalPotassium = mg / 1000.0
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        potassiumField.accessibilityHint = "Change your daily potassium goal in milligrams".localized()
        scrollView.addSubview(potassiumField)
        
        // Vitamin A (% RDI)
        vitaminAField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change Vitamin A (% RDI)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .numberPad
                let pct = Int((UserData.shared.goalVitaminA / self.RDI_VitA_g) * 100.0 + 0.5)
                tf.text = "\(pct)"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let pct = Double(t) {
                    UserData.shared.goalVitaminA = max(0, pct) / 100.0 * self.RDI_VitA_g
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        vitaminAField.accessibilityHint = "Change your daily Vitamin A goal as a percentage of the recommended daily intake".localized()
        scrollView.addSubview(vitaminAField)
        
        // Vitamin C (% RDI)
        vitaminCField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change Vitamin C (% RDI)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .numberPad
                let pct = Int((UserData.shared.goalVitaminC / self.RDI_VitC_g) * 100.0 + 0.5)
                tf.text = "\(pct)"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let pct = Double(t) {
                    UserData.shared.goalVitaminC = max(0, pct) / 100.0 * self.RDI_VitC_g
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        vitaminCField.accessibilityHint = "Change your daily Vitamin C goal as a percentage of the recommended daily intake".localized()
        scrollView.addSubview(vitaminCField)
        
        // Calcium (% RDI)
        calciumField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change Calcium (% RDI)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .numberPad
                let pct = Int((UserData.shared.goalCalcium / self.RDI_Calcium_g) * 100.0 + 0.5)
                tf.text = "\(pct)"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let pct = Double(t) {
                    UserData.shared.goalCalcium = max(0, pct) / 100.0 * self.RDI_Calcium_g
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        calciumField.accessibilityHint = "Change your daily Calcium goal as a percentage of the recommended daily intake".localized()
        scrollView.addSubview(calciumField)
        
        // Iron (% RDI)
        ironField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Change Iron (% RDI)".localized(),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .numberPad
                let pct = Int((UserData.shared.goalIron / self.RDI_Iron_g) * 100.0 + 0.5)
                tf.text = "\(pct)"
            }
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default) { _ in
                if let t = alert.textFields?.first?.text, let pct = Double(t) {
                    UserData.shared.goalIron = max(0, pct) / 100.0 * self.RDI_Iron_g
                    self.refresh()
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            self.present(alert, animated: true)
        }, for: .touchUpInside)
        ironField.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        ironField.accessibilityHint = "Change your daily Iron goal as a percentage of the recommended daily intake".localized()
        scrollView.addSubview(ironField)
    }
}
