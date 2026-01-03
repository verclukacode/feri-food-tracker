//
//  EntriesViewController.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 17. 12. 25.
//

import UIKit

class EntriesViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //Data
    private var completion: (()->())? = nil
    convenience init(completion: (() -> ())?) {
        self.init()
        self.completion = completion
    }
    
    private var data: [FoodLogData] = []
    
    //UI
    let emptyLabel = UILabel()
    let tableView = UITableView()
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
        tableView.frame = view.bounds
        emptyLabel.frame = view.bounds
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "xmark"), target: self, action: #selector(onClose))
        self.title = "Entries"
        
        
        view.backgroundColor = .systemBackground
        
        tableView.register(EntryCell.self, forCellReuseIdentifier: "cell")
        tableView.allowsSelection = false
        tableView.separatorEffect = .none
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        emptyLabel.text = "Nothing here"
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 17)
        emptyLabel.textColor = .secondaryLabel
        tableView.addSubview(emptyLabel)
        
        self.refresh()
    }
    
    
    @objc
    func onClose() {
        self.completion?()
        self.dismiss(animated: true)
    }
    
    
    func refresh() {
        CloudManager.shared.getAll(for: ViewController.selectedDate) { logs in
            self.data = logs.sorted(by: { $0.mealRawValue < $1.mealRawValue })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.emptyLabel.isHidden = !self.data.isEmpty
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! EntryCell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let resultCell = cell as? EntryCell {
            resultCell.refresh(with: self.data[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}


extension EntriesViewController {
    
    class EntryCell: UITableViewCell {
        
        //Data
        var data: FoodLogData?
        
        
        //UI
        let myFoodIcon = UIImageView()
        let backView = UIView()
        let mainText = UILabel()
        let descriptionText = UILabel()
        let button = UIButton()
        
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            backView.frame = CGRect(x: 15, y: 10, width: self.frame.width - 30, height: self.frame.height - 10)
            backView.layer.cornerRadius = 20
            
            let labelY = (backView.frame.height - 25 - 20) / 2
            
            myFoodIcon.frame = CGRect(x: 15, y: 0, width: 0, height: backView.frame.height)
            mainText.frame = CGRect(x: 15, y: labelY, width: backView.frame.width - 65, height: 25)
            
            descriptionText.frame = CGRect(x: mainText.frame.minX, y: mainText.frame.maxY, width: mainText.frame.width, height: 20)
            
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
            
            
            button.addAction(UIAction(handler: { _ in
                guard let data = self.data else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                
                let alert = UIAlertController(title: self.data?.name ?? "Choose", message: nil, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Log again", style: .default, handler: { _ in
                    if let new = data.convertToUSDAFood() {
                        self.viewController?.present(UINavigationController(rootViewController: LogFoodViewController(food: new) {
                            if let vc = self.viewController as? EntriesViewController {
                                vc.refresh()
                            }
                        }), animated: true)
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                    
                    let viewController = EditFoodLogViewController(log: data) {
                        if let vc = self.viewController as? EntriesViewController {
                            vc.refresh()
                        }
                    }
                    
                    self.viewController?.present(UINavigationController(rootViewController: viewController), animated: true)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    
                    alert.dismiss(animated: true) {
                        let confirmAlert = UIAlertController(title: "Are you sure?", message: "You cannot undo this...", preferredStyle: .alert)
                        confirmAlert.addAction(UIAlertAction(title: "Continue", style: .destructive, handler: { _ in
                            CloudManager.shared.deleteLog(data)
                            if let vc = self.viewController as? EntriesViewController {
                                vc.refresh()
                            }
                        }))
                        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        
                        self.viewController?.present(confirmAlert, animated: true)
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                alert.sheetPresentationController?.sourceView = self.backView
                self.viewController?.present(alert, animated: true)
                
            }), for: .touchUpInside)
            self.addSubview(button)
            
        }
        
        func refresh(with data: FoodLogData) {
            
            self.data = data
            
            var name = data.name.capitalized
            self.myFoodIcon.isHidden = true
            
            if name.count > 30 {
                name = name.prefix(27) + "..."
            }

            mainText.text = name
            descriptionText.text = "\(data.meal.rawValue.capitalized) •\(Int(data.calories)) kcal • \(Int(data.portionInGrams))g"
            
            self.layoutSubviews()
        }
        
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
    }
    
}
