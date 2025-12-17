//
//  LogFoodViewController.swift
//  CitrusNutrition
//
//  Created by Luka Verč on 1. 10. 25.
//

import UIKit

class LogFoodBrowseViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //Data
    static var previousSearchResult = ""
    static var previousSearchFoodLocation: SearchFoodLocation = .allFoods
    static var previousUSDASearchResult = ""
    
    var isFirstOpen = true
    var completion: (()->())?
    var selectedDate: Date = .now
    convenience init(selectedDate: Date, completion: (() -> ())?) {
        self.init()
        self.completion = completion
        self.selectedDate = selectedDate
    }
    
    enum SearchFoodLocation {
        case allFoods
        case myFoods
    }
    
    static var usdaSearchResults: [APIManager.FoodData] = []
    
    //UI
    let searchBar = UISearchBar()
    
    let resultsTitleView = UILabel()
    
    let tableView = UITableView()
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isFirstOpen {
            self.searchBar.becomeFirstResponder()
            self.isFirstOpen = false
        }
        
        // Announce screen for VoiceOver
        UIAccessibility.post(notification: .screenChanged, argument: self.navigationItem.titleView ?? self.title)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        searchBar.frame = CGRect(x: 5, y: view.safeAreaInsets.top + 15, width: view.frame.width - 10, height: 50)
        
        
        resultsTitleView.frame = CGRect(x: 15, y: searchBar.frame.maxY + 30, width: view.frame.width - 30, height: 25)
        
        
        tableView.frame = CGRect(x: 0, y: resultsTitleView.frame.maxY, width: view.frame.width, height: view.frame.height - resultsTitleView.frame.maxY)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "xmark"), target: self, action: #selector(onClose))
        self.title = "Log food"
        
        
        view.backgroundColor = .systemBackground
        
        
        searchBar.searchTextField.delegate = self
        searchBar.placeholder = "Search foods"
        searchBar.searchBarStyle = .minimal
        searchBar.returnKeyType = .done
        view.addSubview(searchBar)
        
        
        if LogFoodBrowseViewController.previousSearchResult != "" {
            self.resultsTitleView.text = LogFoodBrowseViewController.usdaSearchResults.isEmpty ? "No results" : "Results"
        }
        resultsTitleView.textColor = .label
        resultsTitleView.font = .systemFont(ofSize: 20, weight: .bold)
        view.addSubview(resultsTitleView)
        
        
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "cell")
        tableView.allowsSelection = false
        tableView.separatorEffect = .none
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }
    
    
    @objc
    func onClose() {
        self.completion?()
        self.dismiss(animated: true)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        self.search()
        return true
    }
    
    
    func search() {
        
        self.resultsTitleView.text = "\("Searching")..."
        resultsTitleView.accessibilityLabel = resultsTitleView.text
        UIAccessibility.post(notification: .announcement, argument: resultsTitleView.text)
        
        guard let text = self.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            LogFoodBrowseViewController.usdaSearchResults = []
            self.tableView.reloadData()
            self.resultsTitleView.text = "Results"
            resultsTitleView.accessibilityLabel = resultsTitleView.text
            return
        }
        
        if LogFoodBrowseViewController.previousSearchResult == text {
            self.resultsTitleView.text = "Results"
            resultsTitleView.accessibilityLabel = resultsTitleView.text
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        
        if LogFoodBrowseViewController.previousUSDASearchResult == text {
            if LogFoodBrowseViewController.usdaSearchResults.isEmpty {
                self.resultsTitleView.text = "No results"
                resultsTitleView.accessibilityLabel = resultsTitleView.text
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                self.resultsTitleView.text = "Results"
                resultsTitleView.accessibilityLabel = resultsTitleView.text
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            self.tableView.reloadData()
            return
        }
        
        LogFoodBrowseViewController.previousSearchResult = text
        
        APIManager.shared.searchFoods(prompt: text) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let array):
                    if array.isEmpty {
                        self.resultsTitleView.text = "No results"
                        self.resultsTitleView.accessibilityLabel = self.resultsTitleView.text
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    } else {
                        self.resultsTitleView.text = "Results"
                        self.resultsTitleView.accessibilityLabel = self.resultsTitleView.text
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    LogFoodBrowseViewController.previousUSDASearchResult = text
                    LogFoodBrowseViewController.usdaSearchResults = array
                    self.tableView.reloadData()
                case .failure:
                    self.resultsTitleView.text = "Error"
                    self.resultsTitleView.accessibilityLabel = self.resultsTitleView.text
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return LogFoodBrowseViewController.usdaSearchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SearchResultCell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let resultCell = cell as? SearchResultCell {
            resultCell.refresh(with: LogFoodBrowseViewController.usdaSearchResults[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}


extension LogFoodBrowseViewController {
    
    class SearchResultCell: UITableViewCell {
        
        //Data
        var data: APIManager.FoodData?
        
        
        //UI
        let myFoodIcon = UIImageView()
        let backView = UIView()
        let mainText = UILabel()
        let descriptionText = UILabel()
        let arrowIcon = UIImageView()
        let button = UIButton()
        
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            backView.frame = CGRect(x: 15, y: 10, width: self.frame.width - 30, height: self.frame.height - 10)
            backView.layer.cornerRadius = 20
            
            let labelY = (backView.frame.height - 25 - 20) / 2
            
            if let data = self.data, data.isSavedToMyFoods {
                myFoodIcon.frame = CGRect(x: 15, y: 0, width: 22, height: backView.frame.height)
                mainText.frame = CGRect(x: myFoodIcon.frame.maxX + 10, y: labelY, width: backView.frame.width - 60 - myFoodIcon.frame.maxX, height: 25)
            } else {
                myFoodIcon.frame = CGRect(x: 15, y: 0, width: 0, height: backView.frame.height)
                mainText.frame = CGRect(x: 15, y: labelY, width: backView.frame.width - 65, height: 25)
            }
            
            descriptionText.frame = CGRect(x: mainText.frame.minX, y: mainText.frame.maxY, width: mainText.frame.width, height: 20)
            
            arrowIcon.frame = CGRect(x: backView.frame.width - 40, y: (backView.frame.height - 25) / 2, width: 25, height: 25)
            
            button.frame = self.bounds
            
        }
        
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.contentView.isHidden = true
            self.backgroundColor = .clear
            
            
            backView.backgroundColor = .secondarySystemBackground
            backView.layer.cornerCurve = .continuous
            self.addSubview(backView)
            
            myFoodIcon.tintColor = .label
            myFoodIcon.contentMode = .center
            myFoodIcon.image = UIImage(systemName: "bookmark.fill")?.withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 17, weight: .semibold)))
            backView.addSubview(myFoodIcon)
            
            mainText.font = .systemFont(ofSize: 17, weight: .semibold)
            mainText.textColor = .label
            mainText.textAlignment = .left
            backView.addSubview(mainText)
            
            descriptionText.font = .systemFont(ofSize: 14, weight: .regular)
            descriptionText.textColor = .secondaryLabel
            descriptionText.textAlignment = .left
            backView.addSubview(descriptionText)
            
            arrowIcon.image = UIImage(systemName: "chevron.right")?.withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20, weight: .regular)))
            arrowIcon.tintColor = .secondaryLabel
            arrowIcon.contentMode = .center
            backView.addSubview(arrowIcon)
            
            
            button.addAction(UIAction(handler: { _ in
                guard let data = self.data else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.viewController?.navigationController?.pushViewController(LogFoodViewController(food: data), animated: true)
            }), for: .touchUpInside)
            self.addSubview(button)
            
            // Accessibility: the button acts as the single accessible element for the cell
            button.isAccessibilityElement = true
            backView.isAccessibilityElement = false
            mainText.isAccessibilityElement = false
            descriptionText.isAccessibilityElement = false
            myFoodIcon.isAccessibilityElement = false
            arrowIcon.isAccessibilityElement = false
        }
        
        func refresh(with data: APIManager.FoodData) {
            
            self.data = data
            
            var name = data.isSavedToMyFoods ? "" + data.name.capitalized : data.name.capitalized
            self.myFoodIcon.isHidden = !data.isSavedToMyFoods
            
            if name.count > 25, data.isSavedToMyFoods {
                name = name.prefix(22) + "..."
            } else if name.count > 30 {
                name = name.prefix(27) + "..."
            }

            mainText.text = name
            descriptionText.text = "\(Int(data.calories(for: data.defaultServingSize))) kcal • \(Int(data.defaultServingSize))g"
            
            self.layoutSubviews()
        }
        
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
    }
    
}


extension UIView {
    var viewController: UIViewController? {
        var nextResponder: UIResponder? = self
        while let responder = nextResponder {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            nextResponder = responder.next
        }
        return nil
    }
}
