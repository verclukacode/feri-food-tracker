//
//  NutritionListViewController.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 1. 10. 25.
//

import UIKit

class NutritionListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Data
    var data: [(String, UIColor, Double, Double)] = []
    
    var isAlwaysShowingPremium: Bool = false
    
    var foodLog: FoodLogData?
    convenience init(food: FoodLogData) {
        self.init()
        self.foodLog = food
        
        self.navigationItem.titleView = {
            var text = food.name.capitalized
            if text.count > 30 {
                text = String(text.prefix(27)) + "..."
            }
            
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.textColor = .label
            label.sizeToFit()
            return label
        }()
    }
    
    var date: Date = .now
    convenience init(date: Date) {
        self.init()
        self.date = date
        
        self.navigationItem.titleView = {
            let label = UILabel()
            label.text = "Nutrition".localized()
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.textColor = .label
            label.sizeToFit()
            return label
        }()
    }
    
    var usdaFood: APIManager.FoodData?
    var usdaAmount: Double = 0
    convenience init(food: APIManager.FoodData, amount: Double) {
        self.init()
        self.usdaFood = food
        self.usdaAmount = amount
        
        self.navigationItem.titleView = {
            var text = food.name.capitalized
            if text.count > 30 {
                text = String(text.prefix(27)) + "..."
            }
            
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.textColor = .label
            label.sizeToFit()
            return label
        }()
    }
    
    // UI
    let tableView = UITableView()
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        tableView.contentInset.bottom = 30
        tableView.contentInset.top = 15
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        tableView.register(NutritionCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.separatorEffect = .none
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        configureAccessibility()
        refresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.refresh()
        
        // Move VoiceOver focus to the title
        UIAccessibility.post(
            notification: .screenChanged,
            argument: navigationItem.titleView
        )
    }
    
    // MARK: - Accessibility
    
    private func configureAccessibility() {
        // Back button
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Back".localized()
        navigationItem.leftBarButtonItem?.accessibilityHint = "Go back".localized()
        
        // Table description
        tableView.isAccessibilityElement = false
        tableView.accessibilityLabel = "Nutrition list".localized()
        tableView.accessibilityHint = "Shows nutrients and how much you reached compared to your goal".localized()
    }
    
    
    // MARK: - Data
    
    func refresh() {
        data.removeAll()
        
        if let food = self.foodLog {
            data.append(("Protein".localized(), UIColor.accent, food.protein, UserData.shared.goalProtein))
            data.append(("Carbs".localized(), UIColor.accent, food.carbs, UserData.shared.goalCarbs))
            data.append(("Fat".localized(), UIColor.accent, food.fat, UserData.shared.goalFat))
            data.append(("Saturated fat".localized(), UIColor.accent, food.saturatedFat, UserData.shared.goalSaturatedFat))
            data.append(("Monounsaturated fat".localized(), UIColor.accent, food.monosaturatedFat, UserData.shared.goalMonosaturatedFat))
            data.append(("Fiber".localized(), UIColor.accent, food.fiber, UserData.shared.goalFiber))
            data.append(("Sugar".localized(), UIColor.accent, food.sugar, UserData.shared.goalSugar))
            data.append(("Cholesterol".localized(), UIColor.accent, food.cholesterol, UserData.shared.goalCholesterol))
            data.append(("Sodium".localized(), UIColor.accent, food.sodium, UserData.shared.goalSodium))
            data.append(("Potassium".localized(), UIColor.accent, food.potassium, UserData.shared.goalPotassium))
            data.append(("Vitamin A".localized(), UIColor.accent, food.vitaminA, UserData.shared.goalVitaminA))
            data.append(("Vitamin C".localized(), UIColor.accent, food.vitaminC, UserData.shared.goalVitaminC))
            data.append(("Calcium".localized(), UIColor.accent, food.calcium, UserData.shared.goalCalcium))
            data.append(("Iron".localized(), UIColor.accent, food.iron, UserData.shared.goalIron))
            
            tableView.reloadData()
            
        } else if let food = self.usdaFood {
            
            data.append(("Protein".localized(), UIColor.accent, food.amount(of: .proteinG, for: usdaAmount) ?? 0, UserData.shared.goalProtein))
            data.append(("Carbs".localized(), UIColor.accent, food.amount(of: .carbsG, for: usdaAmount) ?? 0, UserData.shared.goalCarbs))
            data.append(("Fat".localized(), UIColor.accent, food.amount(of: .fatG, for: usdaAmount) ?? 0, UserData.shared.goalFat))
            data.append(("Saturated fat".localized(), UIColor.accent, food.amount(of: .satFatG, for: usdaAmount) ?? 0, UserData.shared.goalSaturatedFat))
            data.append(("Monounsaturated fat".localized(), UIColor.accent, food.amount(of: .monoFatG, for: usdaAmount) ?? 0, UserData.shared.goalMonosaturatedFat))
            data.append(("Fiber".localized(), UIColor.accent, food.amount(of: .fiberG, for: usdaAmount) ?? 0, UserData.shared.goalFiber))
            data.append(("Sugar".localized(), UIColor.accent, food.amount(of: .sugarsG, for: usdaAmount) ?? 0, UserData.shared.goalSugar))
            data.append(("Cholesterol".localized(), UIColor.accent, (food.amount(of: .cholesterolMg, for: usdaAmount) ?? 0) / 1000, UserData.shared.goalCholesterol))
            data.append(("Sodium".localized(), UIColor.accent, (food.amount(of: .sodiumMg, for: usdaAmount) ?? 0) / 1000, UserData.shared.goalSodium))
            data.append(("Potassium".localized(), UIColor.accent, (food.amount(of: .potassiumMg, for: usdaAmount) ?? 0) / 1000, UserData.shared.goalPotassium))
            data.append(("Vitamin A".localized(), UIColor.accent, (food.amount(of: .vitaminA_RAE_ug, for: usdaAmount) ?? 0) / 1_000_000, UserData.shared.goalVitaminA))
            data.append(("Vitamin C".localized(), UIColor.accent, (food.amount(of: .vitaminC_mg, for: usdaAmount) ?? 0) / 1000, UserData.shared.goalVitaminC))
            data.append(("Calcium".localized(), UIColor.accent, (food.amount(of: .calciumMg, for: usdaAmount) ?? 0) / 1000, UserData.shared.goalCalcium))
            data.append(("Iron".localized(), UIColor.accent, (food.amount(of: .ironMg, for: usdaAmount) ?? 0) / 1000, UserData.shared.goalIron))
            
            tableView.reloadData()
            
        } else {
            
            CloudManager.shared.getAll(for: self.date) { [weak self] result in
                var protein: Double = 0
                var carbs: Double = 0
                var fiber: Double = 0
                var sugar: Double = 0
                var fat: Double = 0
                var saturatedFat: Double = 0
                var monosaturatedFat: Double = 0
                var cholesterol: Double = 0
                var sodium: Double = 0
                var potassium: Double = 0
                var vitaminA: Double = 0
                var vitaminC: Double = 0
                var calcium: Double = 0
                var iron: Double = 0
                
                for food in result {
                    protein += food.protein
                    carbs += food.carbs
                    fiber += food.fiber
                    sugar += food.sugar
                    fat += food.fat
                    saturatedFat += food.saturatedFat
                    monosaturatedFat += food.monosaturatedFat
                    cholesterol += food.cholesterol
                    sodium += food.sodium
                    potassium += food.potassium
                    vitaminA += food.vitaminA
                    vitaminC += food.vitaminC
                    calcium += food.calcium
                    iron += food.iron
                }
                
                self?.data.append(("Protein".localized(), UIColor.accent, protein, UserData.shared.goalProtein))
                self?.data.append(("Carbs".localized(), UIColor.accent, carbs, UserData.shared.goalCarbs))
                self?.data.append(("Fat".localized(), UIColor.accent, fat, UserData.shared.goalFat))
                self?.data.append(("Saturated fat".localized(), UIColor.accent, saturatedFat, UserData.shared.goalSaturatedFat))
                self?.data.append(("Monounsaturated fat".localized(), UIColor.accent, monosaturatedFat, UserData.shared.goalMonosaturatedFat))
                self?.data.append(("Fiber".localized(), UIColor.accent, fiber, UserData.shared.goalFiber))
                self?.data.append(("Sugar".localized(), UIColor.accent, sugar, UserData.shared.goalSugar))
                self?.data.append(("Cholesterol".localized(), UIColor.accent, cholesterol, UserData.shared.goalCholesterol))
                self?.data.append(("Sodium".localized(), UIColor.accent, sodium, UserData.shared.goalSodium))
                self?.data.append(("Potassium".localized(), UIColor.accent, potassium, UserData.shared.goalPotassium))
                self?.data.append(("Vitamin A".localized(), UIColor.accent, vitaminA, UserData.shared.goalVitaminA))
                self?.data.append(("Vitamin C".localized(), UIColor.accent, vitaminC, UserData.shared.goalVitaminC))
                self?.data.append(("Calcium".localized(), UIColor.accent, calcium, UserData.shared.goalCalcium))
                self?.data.append(("Iron".localized(), UIColor.accent, iron, UserData.shared.goalIron))
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    
    // MARK: - Actions
    
    @objc
    override func onClose() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NutritionCell
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        if let nutritionCell = cell as? NutritionCell {
            nutritionCell.refresh(data: data[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    
    // MARK: - Cell
    
    class NutritionCell: UITableViewCell {
        
        let backView = UIView()
        let titleView = UILabel()
        let valueLabel = UILabel()
        let progressBar = ProgressBar()
        let button = UIButton()
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            backView.frame = CGRect(
                x: 15,
                y: 10,
                width: self.frame.width - 30,
                height: self.frame.height - 10
            )
            backView.layer.cornerRadius = 24
            
            titleView.frame = CGRect(x: 15, y: 15, width: backView.frame.width - 30, height: 20)
            valueLabel.frame = titleView.frame
            
            progressBar.frame = CGRect(
                x: 15,
                y: valueLabel.frame.maxY + 6,
                width: backView.frame.width - 30,
                height: 10
            )
            
            button.frame = backView.bounds
        }
        
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            contentView.isHidden = true
            backgroundColor = .clear
            
            backView.backgroundColor = .secondarySystemBackground
            backView.layer.cornerCurve = .continuous
            addSubview(backView)
            
            titleView.textAlignment = .left
            titleView.textColor = .label
            titleView.font = .systemFont(ofSize: 17, weight: .semibold)
            backView.addSubview(titleView)
            
            valueLabel.textAlignment = .right
            valueLabel.textColor = .secondaryLabel
            valueLabel.font = .systemFont(ofSize: 17, weight: .regular)
            backView.addSubview(valueLabel)
            
            progressBar.lineGlow.isHidden = true
            progressBar.backColor = .systemBackground
            backView.addSubview(progressBar)
            
            // Paywall button (covers whole cell visually)
            button.addAction(UIAction(handler: { _ in
                //Nothing
            }), for: .touchUpInside)
            button.isAccessibilityElement = false
            backView.addSubview(button)
            
            // Accessibility: treat whole cell as a single element
            isAccessibilityElement = true
            backView.isAccessibilityElement = false
            titleView.isAccessibilityElement = false
            valueLabel.isAccessibilityElement = false
            progressBar.isAccessibilityElement = false
        }
        
        
        func refresh(data: (String, UIColor, Double, Double)) {
            let current = data.2
            let goal = data.3
            
            titleView.text = data.0
            
            var valueText: String
            var accessibilityUnit: String
            
            if goal >= 5 {
                // grams
                let currentG = Int(current.rounded())
                let goalG = Int(goal.rounded())
                valueText = "\(currentG) / \(goalG)g"
                accessibilityUnit = "grams".localized()
                
            } else if goal >= 0.01 {
                // milligrams
                let currentMg = Int((current * 1000).rounded())
                let goalMg = Int((goal * 1000).rounded())
                valueText = "\(currentMg) / \(goalMg)mg"
                accessibilityUnit = "milligrams".localized()
                
            } else {
                // micrograms
                let currentUg = Int((current * 1_000_000).rounded())
                let goalUg = Int((goal * 1_000_000).rounded())
                valueText = "\(currentUg) / \(goalUg)µg"
                accessibilityUnit = "micrograms".localized()
            }
            
            valueLabel.text = valueText
            
            let ratio = goal > 0 ? current / goal : 0
            progressBar.setUp(with: ratio, color: data.1)
            
            // Accessibility – unlocked: static info
            accessibilityTraits = [.staticText]
            let nutrientName = data.0
            accessibilityLabel = nutrientName
            accessibilityValue = "\(valueLabel.text ?? "") (\("of your goal".localized())) \(accessibilityUnit)"
        }
        
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
