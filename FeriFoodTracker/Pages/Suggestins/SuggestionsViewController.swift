//
//  SuggestionsViewController.swift
//  Citrus
//
//  Created by Luka Verč on 7. 10. 25.
//

import UIKit
import StoreKit

class SuggestionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    //Data
    private var data: [SuggestionsData] = []
    
    private var lastRefreshDate: Date?
    
    private var isLoading: Bool = false
    private var showPlaceholderCellsOnLoading: Bool = false
    
    //Body
    private let headerView = InsightsHeader()
    
    private let refreshControl = UIRefreshControl()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let emptyLabel = UILabel()
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.refresh()
        
        //Loading
        if #available(iOS 18.0, *) {
            self.tabBarController?.setTabBarHidden(false, animated: false)
        }
        
        if let date = self.lastRefreshDate, !Calendar.current.isDateInToday(date) {
            self.showPlaceholderCellsOnLoading = true
            self.refresh()
        }
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        tableView.contentInset.top = 30
        tableView.contentInset.bottom = 30
        
        emptyLabel.frame = view.bounds
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "xmark"), target: self, action: #selector(self.onClose))
        
        //Background
        view.backgroundColor = .systemBackground
        
        tableView.register(InsightsCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.separatorEffect = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.accessibilityIdentifier = "SuggestionsTableView"
        view.addSubview(tableView)
        
        refreshControl.addTarget(self, action: #selector(onRefreshControl), for: .valueChanged)
        refreshControl.tintColor = .label
        refreshControl.accessibilityLabel = "Pull to refresh suggestions".localized()
        tableView.refreshControl = refreshControl
        
        emptyLabel.text = "\("No Insights for now".localized())\n\n\("Here you will uncover personalized nutrition strategies, driven by food data you input into the app.".localized())"
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = UIFont.systemFont(ofSize: 17)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isAccessibilityElement = true
        emptyLabel.accessibilityLabel = emptyLabel.text
        view.addSubview(emptyLabel)
        
        
        //Refesh
        self.showPlaceholderCellsOnLoading = true
        
    }
    
    //Refresh
    @objc
    private func onRefreshControl() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // Accessibility: announce refresh
        UIAccessibility.post(notification: .announcement, argument: "Refreshing suggestions".localized())
        self.refresh()
    }
    
    
    @objc
    public func refresh() {
        
        if self.isLoading {
            return
        } else {
            self.isLoading = true
        }
        
        print("Started refreshing insights")
        
        self.emptyLabel.isHidden = true

        // Set loading state and reload to show loading placeholders (2 rows for example)
        if self.showPlaceholderCellsOnLoading {
            self.tableView.reloadData()
        }

        HealthManager.shared.getSuggestions { newData in
            DispatchQueue.main.async {
                // Ensure we are not in loading state anymore
                self.showPlaceholderCellsOnLoading = false

                // Store the new data
                self.data = newData

                // Reload the table view completely after data is loaded (no batch updates during transition)
                self.tableView.reloadData()

                // Dismiss loading views and stop refresh control
                self.refreshControl.endRefreshing()
                
                self.lastRefreshDate = .now
                
                self.isLoading = false
                
                // Accessibility: announce updated count
                let countText: String
                if newData.isEmpty {
                    countText = "No suggestions available today.".localized()
                } else if newData.count == 1 {
                    countText = "You have 1 suggestion today.".localized()
                } else {
                    countText = String(
                        format: "You have %@ suggestions today.".localized(),
                        "\(newData.count)"
                    )
                }
                UIAccessibility.post(notification: .announcement, argument: countText)
            }
        }
    }
    
    //TableView delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        self.emptyLabel.isHidden = (self.showPlaceholderCellsOnLoading || self.data.count > 0)
        
        return self.showPlaceholderCellsOnLoading ? 3 : self.data.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70 + self.heightForSubTitle() + 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! InsightsCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !self.showPlaceholderCellsOnLoading && self.data[indexPath.row].isOpened {
            return self.getHeightForOpenCell(row: indexPath.row)
        } else {
            return 450
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? InsightsCell {
            if self.showPlaceholderCellsOnLoading {
                cell.refresh(with: SuggestionsData(id: "Empty", title: "", icon: nil, description: "", color: .clear, graph: [], safeArea: nil, isPresentingTime: false, importance: 0, answer: "", tag: .empty))
            } else {
                cell.refresh(with: self.data[indexPath.row])
            }
            cell.page = self
            cell.index = indexPath.row
        }
    }
    
    func getHeightForOpenCell(row: Int) -> CGFloat {
        let textView = UITextView()
        textView.frame = CGRect(x: 30, y: 0, width: view.frame.width - 60, height: 1000)
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.text = self.data[row].answer
        textView.sizeToFit()
        return textView.frame.height + 200
    }
    
    func heightForSubTitle() -> CGFloat {
        if self.showPlaceholderCellsOnLoading {
            self.headerView.titleDescriptionView.text = "\("Getting your Suggestions".localized())..."
        } else if self.data.isEmpty {
            self.headerView.titleDescriptionView.text = ""
            return 0
        } else {
            self.headerView.titleDescriptionView.text = "Here are COUNT suggestions for you today.".localized().replacingOccurrences(of: "COUNT", with: "\(self.data.count)")
            if self.data.count == 1 {
                self.headerView.titleDescriptionView.text = "Here is COUNT suggestion for you today.".localized().replacingOccurrences(of: "COUNT", with: "\(self.data.count)")
            }
        }
        
        self.headerView.titleDescriptionView.frame = CGRect(x: 15, y: 0, width: view.frame.width - 30, height: 1000)
        self.headerView.titleDescriptionView.sizeToFit()
        self.headerView.titleDescriptionView.frame = CGRect(x: 15, y: 0, width: view.frame.width - 30, height: self.headerView.titleDescriptionView.frame.height)
        
        return self.headerView.titleDescriptionView.frame.height
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        if self.data.isEmpty {
            return 0
        }
        
        let label = UILabel()
        label.frame = CGRect(x: 15, y: 0, width: view.frame.width - 30, height: 1000)
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Don't take this too seriously. They're just Luka's suggestions, not medical advice."
        label.numberOfLines = 0
        label.sizeToFit()
        return label.frame.height + 20
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        if self.data.isEmpty {
            return nil
        }
        
        return TableViewTextFooter()
    }
    
    
    //Header
    private class InsightsHeader: UIView {
        
        public let titleView = UILabel()
        public let titleDescriptionView = UILabel()
        
        override func layoutSubviews() {
            titleView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: 40)
            titleDescriptionView.frame = CGRect(x: 15, y: titleView.frame.maxY + 10, width: self.frame.width - 30, height: self.frame.height - 80)
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.addSubview(titleView)
            titleView.text = "Suggestions".localized()
            titleView.font = UIFont.systemFont(ofSize: 32, weight: .bold)
            titleView.textColor = .label
            titleView.textAlignment = .left
            
            self.addSubview(titleDescriptionView)
            titleDescriptionView.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            titleDescriptionView.textColor = .secondaryLabel
            titleDescriptionView.textAlignment = .left
            titleDescriptionView.numberOfLines = 0
            
            // Accessibility: treat this as one header block
            self.isAccessibilityElement = true
            self.accessibilityTraits = .header
            self.accessibilityLabel = {
                let title = titleView.text ?? ""
                let desc = titleDescriptionView.text ?? ""
                if desc.isEmpty {
                    return title
                } else {
                    return "\(title). \(desc)"
                }
            }()
            titleView.isAccessibilityElement = false
            titleDescriptionView.isAccessibilityElement = false
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    
    //Cell
    private class InsightsCell: UITableViewCell {
        
        //Data
        private var data: SuggestionsData?
        public var page: SuggestionsViewController?
        public var index: Int = 0
        
        //UI
        private let backView = UIView()
        
        private let iconView = UIImageView()
        private let titleLabel = UILabel()
        private let descriptionLabel = UILabel()
        
        private let graphView = GraphVC.GraphView()
        
        private let actionButton = UIButton()
        
        private let answerLabel = UITextView()
        
        private let emptyIcon = UIImageView()
        
        override func layoutSubviews() {
            
            backView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: max(self.frame.height - 15, 0))
            backView.layer.cornerRadius = 24
            //backView.setDefaultShadow()
            
            iconView.frame = CGRect(x: 15, y: 30, width: 30, height: 30)
            titleLabel.frame = CGRect(x: iconView.frame.maxX + 5, y: 30, width: backView.frame.width - iconView.frame.maxX - 20, height: 30)
            descriptionLabel.frame = CGRect(x: 15, y: titleLabel.frame.maxY, width: backView.frame.width - 30, height: 55)
            
            graphView.frame = CGRect(x: 10, y: descriptionLabel.frame.maxY + 10, width: backView.frame.width - 10, height: 200)
            
            answerLabel.frame = CGRect(x: 15, y: descriptionLabel.frame.minY + 15, width: backView.frame.width - 30, height: backView.frame.height - 185)
            
            actionButton.frame = CGRect(x: (backView.frame.width - 200) / 2, y: answerLabel.frame.maxY + 30, width: 200, height: 50)
            
            emptyIcon.frame = backView.bounds
            emptyIcon.layer.cornerRadius = 24
            
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.contentView.isHidden = true
            self.backgroundColor = .clear
            
            backView.backgroundColor = .secondarySystemBackground
            backView.layer.cornerCurve = .continuous
            self.addSubview(backView)
            
            
            iconView.image = UIImage(systemName: "heart.fill")
            iconView.tintColor = .systemPurple
            iconView.contentMode = .scaleAspectFit
            iconView.isAccessibilityElement = false
            backView.addSubview(iconView)
            
            titleLabel.text = "Title...".localized()
            titleLabel.textAlignment = .left
            titleLabel.textColor = .label
            titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            titleLabel.isAccessibilityElement = true
            backView.addSubview(titleLabel)
            
            descriptionLabel.text = "Description...".localized()
            descriptionLabel.numberOfLines = 2
            descriptionLabel.adjustsFontSizeToFitWidth = true
            descriptionLabel.textColor = .secondaryLabel
            descriptionLabel.font = UIFont.systemFont(ofSize: 17)
            descriptionLabel.backgroundColor = .clear
            descriptionLabel.isAccessibilityElement = true
            backView.addSubview(descriptionLabel)
            
            answerLabel.textAlignment = .left
            answerLabel.font = UIFont.systemFont(ofSize: 17)
            answerLabel.textColor = .label
            answerLabel.isEditable = false
            answerLabel.isSelectable = false
            answerLabel.backgroundColor = .clear
            answerLabel.isScrollEnabled = false
            answerLabel.isAccessibilityElement = true
            backView.addSubview(answerLabel)
            
            graphView.backgroundColor = .clear
            graphView.displayZeroValues = true
            graphView.isAccessibilityElement = false   // decorative chart; suggestion is described in text
            backView.addSubview(graphView)
            
            actionButton.setTitle("Action".localized(), for: .normal)
            actionButton.backgroundColor = .accent
            actionButton.layer.cornerCurve = .continuous
            actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            actionButton.tintColor = .white
            actionButton.addTarget(self, action: #selector(onOpen), for: .touchUpInside)
            if #available(iOS 26.0, *) {
                actionButton.configuration = .prominentClearGlass()
            }
            actionButton.isAccessibilityElement = true
            backView.addSubview(actionButton)
            
            
            emptyIcon.image = UIImage(systemName: "hourglass")?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 32, weight: .semibold)))
            emptyIcon.tintColor = .secondaryLabel
            emptyIcon.contentMode = .center
            emptyIcon.backgroundColor = .secondarySystemBackground
            emptyIcon.layer.cornerCurve = .continuous
            emptyIcon.isAccessibilityElement = false
            backView.addSubview(emptyIcon)
            
            // Let VoiceOver see the important subviews instead of the cell itself
            self.isAccessibilityElement = false
            backView.isAccessibilityElement = false
        }
        
        public func refresh(with: SuggestionsData) {
            self.data = with
            
            self.iconView.image = with.icon
            self.iconView.tintColor = .accent
            
            self.titleLabel.text = with.title
            self.descriptionLabel.text = with.description
            
            if let safeArea = with.safeArea {
                self.graphView.upperSafeValue = safeArea.x
                self.graphView.lowerSafeValue = safeArea.y
            } else {
                self.graphView.upperSafeValue = 0
                self.graphView.lowerSafeValue = 0
            }
            
            self.graphView.isPresentingTime = with.isPresentingTime
            self.graphView.data = with.graphData
            
            self.answerLabel.text = with.answer
            
            self.emptyIcon.isHidden = !(with.tag == .empty)
            
            // Accessibility configuration for action button
            if with.tag == .empty {
                // Loading placeholder – hide from VoiceOver
                actionButton.isAccessibilityElement = false
                titleLabel.isAccessibilityElement = false
                descriptionLabel.isAccessibilityElement = false
                answerLabel.isAccessibilityElement = false
            } else {
                actionButton.isAccessibilityElement = true
                titleLabel.isAccessibilityElement = true
                descriptionLabel.isAccessibilityElement = !with.isOpened
                answerLabel.isAccessibilityElement = with.isOpened
                
                if with.isOpened {
                    actionButton.accessibilityLabel = "Close suggestion".localized()
                    actionButton.accessibilityHint = "Hides the full explanation for this suggestion.".localized()
                } else {
                    // Use custom action title when provided
                    let buttonTitle = with.actionTitle
                    actionButton.accessibilityLabel = buttonTitle
                    actionButton.accessibilityHint = "Opens a detailed explanation for this suggestion.".localized()
                }
            }
            
            self.refreshOpened()
        }
        
        @objc
        private func onOpen() {
            
            if self.data?.tag == .empty {
                return
            }
            
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            if let data = self.data {
                data.isOpened = !data.isOpened
                
                if let page = self.page {
                    page.tableView.reloadRows(at: [IndexPath(row: self.index, section: 0)], with: .automatic)
                }
            }
        }
        
        private func refreshOpened() {
            if let data = self.data {
                self.descriptionLabel.isHidden = data.isOpened
                self.graphView.isHidden = data.isOpened
                self.answerLabel.isHidden = !data.isOpened
                
                if data.isOpened {
                    self.actionButton.setTitle("Close".localized(), for: .normal)
                    actionButton.setTitleColor(.label, for: .normal)
                    self.actionButton.backgroundColor = .secondarySystemBackground
                    self.actionButton.setImage(nil, for: .normal)
                } else {
                    actionButton.setTitleColor(.white, for: .normal)
                    self.actionButton.backgroundColor = .accent
                    
                    self.actionButton.setImage(nil, for: .normal)
                    self.actionButton.setTitle(data.actionTitle, for: .normal)
                }
                
                self.layoutSubviews()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }

}


enum SuggestionsDataTag: Int {
    case sleep
    case fitness
    case body
    case empty
}

class SuggestionsData {
    
    public var id: String = ""
    
    public var isOpened: Bool = false
    
    public var importance: Double = 0
    
    public var tintColor: UIColor = .systemBlue
    
    public var icon: UIImage?
    
    public var title: String = ""
    public var description: String = ""
    
    public var actionTitle: String = "See suggestions".localized()
    
    public var graphData: [GraphVC.GraphData] = []
    public var isPresentingTime: Bool = false
    public var safeArea: CGPoint?
    
    public var tag: SuggestionsDataTag = .body
    
    public var answer: String = ""
    
    convenience init(id: String, title: String, icon: UIImage?, description: String, color: UIColor, graph: [GraphVC.GraphData] = [], safeArea: CGPoint? = nil, isPresentingTime: Bool = false, importance: Double, answer: String, tag: SuggestionsDataTag) {
        self.init()
        self.id = id
        self.title = title.capitalized
        self.icon = icon
        self.description = description
        self.tintColor = color
        self.graphData = graph
        self.isPresentingTime = isPresentingTime
        self.safeArea = safeArea
        self.answer = answer
        self.importance = importance
        self.tag = tag
    }
    
}


fileprivate class TableViewTextFooter: UIView {
    
    public let label = UILabel()
    
    override func layoutSubviews() {
        label.frame = CGRect(x: 15, y: 20, width: self.frame.width - 30, height: self.frame.height - 20)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Don't take this too seriously. They're just Luka's suggestions, not medical advice."
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.isAccessibilityElement = true
        self.addSubview(label)
        
        isAccessibilityElement = false
        accessibilityElements = [label]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
