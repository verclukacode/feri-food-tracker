//
//  GraphVC.swift
//  Citrus
//
//  Created by Luka Verč on 21. 7. 24.
//

import UIKit

class GraphVC: UIViewController {
    
    private var isPresentingTime: Bool = false
    
    private var shareButton: UIBarButtonItem!
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let graphView = GraphView()
    private let explanationLabel = UILabel()
    private let loadingIndication = UIActivityIndicatorView()
    
    private var articleName: String = ""
    
    
    //Init
    convenience init(title: String, data: [GraphData], showZeroValues: Bool = false, limits: CGPoint? = nil, isPresentingTime: Bool = false, safeArea: CGPoint = CGPoint(x: 0, y: 0), dataIsForOneDay: Bool = false, articleName: String? = nil) {
        self.init()
        
        self.loadingIndication.stopAnimating()
        self.loadingIndication.isHidden = true
        
        self.isPresentingTime = isPresentingTime
        
        self.titleLabel.text = title
        self.graphView.upperSafeValue = safeArea.x
        self.graphView.lowerSafeValue = safeArea.y
        self.graphView.isPresentingTime = isPresentingTime
        self.graphView.presentDataForOneDay = dataIsForOneDay
        if let limits {
            self.graphView.upperValue = limits.x
            self.graphView.lowerValue = limits.y
        } else {
            self.graphView.upperValue = nil
            self.graphView.lowerValue = nil
        }
        
        self.graphView.displayZeroValues = showZeroValues
        
        self.graphView.data = data
        
        self.articleName = articleName ?? ""
        
        if let lastValue = data.last {
            if lastValue.y >= safeArea.x {
                let fullText = "The most recent data point exceeds the recommended guidelines."
                let attributedText = NSMutableAttributedString(string: fullText)
                let belowRange = (fullText as NSString).range(of: "exceeds")
                
                let fullRange = NSMakeRange(0, fullText.count)
                
                attributedText.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: fullRange)
                attributedText.addAttribute(.foregroundColor, value: UIColor.systemOrange, range: belowRange)

                explanationLabel.attributedText = attributedText
            } else if lastValue.y <= safeArea.y {
                let fullText = "The most recent data point falls below the recommended guidelines."
                let attributedText = NSMutableAttributedString(string: fullText)
                let belowRange = (fullText as NSString).range(of: "below")
                
                let fullRange = NSMakeRange(0, fullText.count)
                
                attributedText.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: fullRange)
                attributedText.addAttribute(.foregroundColor, value: UIColor.systemOrange, range: belowRange)

                explanationLabel.attributedText = attributedText
            } else {
                
                let fullText = "The most recent data point is within the recommended guidelines."
                let attributedText = NSMutableAttributedString(string: fullText)
                let belowRange = (fullText as NSString).range(of: "within")
                
                let fullRange = NSMakeRange(0, fullText.count)
                
                attributedText.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: fullRange)
                attributedText.addAttribute(.foregroundColor, value: UIColor.systemGreen, range: belowRange)

                explanationLabel.attributedText = attributedText
            }
        }
        
        self.setUpNavigationBar()
        
    }
    
    override func viewDidLayoutSubviews() {
        
        view.layer.cornerRadius = 24
        view.layer.cornerCurve = .continuous
        
        titleLabel.frame = CGRect(x: 15, y: 15, width: view.frame.width - 30, height: 35)
        
        explanationLabel.frame = CGRect(x: 15, y: 0, width: view.frame.width - 30, height: 1000)
        explanationLabel.sizeToFit()
        explanationLabel.frame = CGRect(x: 15, y: titleLabel.frame.maxY + 10, width: view.frame.width - 30, height: explanationLabel.frame.height)
        
        if let sheet = self.sheetPresentationController, #available(iOS 16.0, *) {
            sheet.animateChanges {
                sheet.detents = [
                    .custom(resolver: { context in
                        return 400 + self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom + self.explanationLabel.frame.height + 10
                    })
                ]
            }
        }
        
        contentView.frame = CGRect(x: 0, y: view.safeAreaInsets.top + 15, width: view.frame.width, height: view.frame.height - (view.safeAreaInsets.top + 15) - view.safeAreaInsets.bottom)
        
        graphView.frame = CGRect(x: 0, y: explanationLabel.frame.maxY + 30, width: view.frame.width, height: contentView.frame.height - (explanationLabel.frame.maxY + 30) - 15)
        
        loadingIndication.frame = contentView.bounds
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Body
        view.backgroundColor = .systemBackground
        
        
        contentView.backgroundColor = .systemBackground
        view.addSubview(contentView)
    
        titleLabel.textAlignment = .left
        titleLabel.adjustsFontSizeToFitWidth = true
        contentView.addSubview(titleLabel)
        
        explanationLabel.font = UIFont.systemFont(ofSize: 17)
        explanationLabel.textAlignment = .left
        explanationLabel.numberOfLines = 0
        contentView.addSubview(explanationLabel)

        graphView.backgroundColor = .clear
        contentView.addSubview(graphView)
        
        loadingIndication.style = .medium
        contentView.addSubview(loadingIndication)
        
    }
    
    //Navigation buttons
    @objc
    override func onClose() {
        self.dismiss(animated: true)
    }
    
    @objc
    private func onInfo() {
        //
    }
    
    @objc
    private func onShare() {
        //
    }
    
    func prepareForLoading() {
        self.loadingIndication.startAnimating()
        self.loadingIndication.isHidden = false
    }
    
    func refresh(title: String,
                 data: [GraphData],
                 showZeroValues: Bool = false,
                 limits: CGPoint? = nil,
                 isPresentingTime: Bool = false,
                 safeArea: CGPoint = CGPoint(x: 0, y: 0),
                 dataIsForOneDay: Bool = false,
                 articleName: String? = nil) {
        
        self.isPresentingTime = isPresentingTime
        
        self.loadingIndication.stopAnimating()
        self.loadingIndication.isHidden = true
        
        self.titleLabel.text = title
        self.graphView.upperSafeValue = safeArea.x
        self.graphView.lowerSafeValue = safeArea.y
        self.graphView.isPresentingTime = isPresentingTime
        self.graphView.presentDataForOneDay = dataIsForOneDay
        if let limits {
            self.graphView.upperValue = limits.x
            self.graphView.lowerValue = limits.y
        } else {
            self.graphView.upperValue = nil
            self.graphView.lowerValue = nil
        }
        
        self.graphView.displayZeroValues = showZeroValues
        
        self.graphView.data = data
        
        self.articleName = articleName ?? ""
        
        if let lastValue = data.last {
            if lastValue.y >= safeArea.x {
                //
            } else if lastValue.y <= safeArea.y {
                //
            } else {
                
                //
            }
        }
        
        self.viewDidLayoutSubviews()
        self.setUpNavigationBar()
    }
    
    private func setUpNavigationBar() {
        //
    }
    
    
    //Data class
    class GraphView: UIView {
        
        private let loadingButton = UIButton()
        private let valueLabel = UILabel()
        private let activityIndicator = UIActivityIndicatorView(style: .medium)
        
        public func setLoading(_ boolean: Bool) {
            guard boolean != isLoading else { return }
            self.isLoading = boolean
        }
        private var isLoading: Bool = false {
            didSet {
                if isLoading/* && SubscriptionVC.isSubscriptionActive()*/ {
                    activityIndicator.startAnimating()
                    self.data = []
                } else {
                    activityIndicator.stopAnimating()
                    setNeedsDisplay()
                }
            }
        }
        
        private var selectedIndex: Int?
        private var selectedValue: GraphData? {
            didSet {
                if let value = selectedValue {
                    let valueText = self.isPresentingTime ? value.y.toHoursMinutesString() : "\(value.y.rounded(toPlaces: 1))"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM yyyy" // Format for month and year
                    let day = Calendar.current.component(.day, from: value.x)
                    
                    let hour = Calendar.current.component(.hour, from: value.x)
                    let minute = Calendar.current.component(.minute, from: value.x)
                    let formattedHour = String(format: "%02d", hour)
                    let formattedMinute = String(format: "%02d", minute)
                    
                    let monthYearString = dateFormatter.string(from: value.x)
                    
                    // Animate the label shrinking and changing opacity
                    UIView.animate(withDuration: 0.1, animations: {
                        self.valueLabel.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                        self.valueLabel.alpha = 0.15
                    }, completion: { _ in
                        // Change the text after the first part of the animation completes
                        if self.presentDataForOneDay {
                            self.valueLabel.text = "\(formattedHour):\(formattedMinute) - \(valueText)"
                        } else {
                            self.valueLabel.text = "\(day)\(day.ordinalSuffix()) \(monthYearString) - \(valueText)"
                        }
                        self.valueLabel.isHidden = false
                        
                        // Animate the label growing back and returning to full opacity
                        UIView.animate(withDuration: 0.1) {
                            self.valueLabel.transform = CGAffineTransform.identity
                            self.valueLabel.alpha = 1.0
                        }
                    })
                } else {
                    // Optionally, hide the label if `selectedValue` is set to `nil`
                    self.valueLabel.isHidden = true
                }
            }
        }

        var data: [GraphData] = [] {
            didSet {
                setNeedsDisplay()
            }
        }
        
        public var displayZeroValues: Bool = false
        
        private var filteredData: [GraphData]{
            if self.displayZeroValues {
                return self.data
            } else {
                return self.data.filter { $0.y > 0 }
            }
        }

        public var isPresentingTime: Bool = false
        public var showingDataForMax10Days: Bool = true // Toggle for showing all dates or up to 5
        public var presentDataForOneDay: Bool = false

        private let margin: CGFloat = 20.0
        private let topMargin: CGFloat = 20.0
        private let bottomMargin: CGFloat = 30.0
        private let rightMargin: CGFloat = 75.0
        private let yLabelOffset: CGFloat = 15.0

        // Safe area values
        public var upperSafeValue: Double = 80.0
        public var lowerSafeValue: Double = 20.0
        
        //Barriers
        public var upperValue: Double?
        public var lowerValue: Double?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            loadingButton.frame = self.bounds
            valueLabel.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.topMargin)
            self.addTouchPoints()
            
            activityIndicator.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.clipsToBounds = true
            
            loadingButton.addAction(UIAction(handler: { action in
//                if !SubscriptionVC.isSubscriptionActive() {
//                    let subscriptionViewController = ThemeNavigationViewController(rootViewController: Subscription2VC())
//                    subscriptionViewController.modalTransitionStyle = .crossDissolve
//                    subscriptionViewController.modalPresentationStyle = .fullScreen
//                    self.viewController?.present(subscriptionViewController, animated: true)
//                }
            }), for: .touchUpInside)
            self.addSubview(loadingButton)
            
            valueLabel.isHidden = true
            valueLabel.textAlignment = .center
            valueLabel.textColor = .secondaryLabel
            valueLabel.font = UIFont.systemFont(ofSize: 14)
            self.addSubview(valueLabel)
            
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = .label
            self.addSubview(activityIndicator)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            
            guard filteredData.count > 1 else { return }
            guard let context = UIGraphicsGetCurrentContext() else { return }

            let width = rect.width - margin - rightMargin
            let height = rect.height - topMargin - bottomMargin
            let yValues = filteredData.map { $0.y }

            var minY = yValues.min() ?? 0
            var maxY = yValues.max() ?? 0

            if let upperValue = self.upperValue, let lowerValue = self.lowerValue {
                minY = min(minY, lowerValue)
                maxY = max(maxY, upperValue)
            }

            let yRange = maxY - minY
            minY -= yRange * 0.25
            maxY += yRange * 0.25

            if minY == maxY {
                minY -= 1
                maxY += 1
            }

            let safeLowerBound = max(minY, min(maxY, lowerSafeValue))
            let safeUpperBound = max(minY, min(maxY, upperSafeValue))
            let yAxisInterval = (maxY - minY) / 9

            let dateFormatter1 = DateFormatter()
            dateFormatter1.dateFormat = presentDataForOneDay ? "hh" : "dd"

            let dateFormatter2 = DateFormatter()
            if presentDataForOneDay {
                dateFormatter2.dateFormat = "a"
                dateFormatter2.amSymbol = "am"
                dateFormatter2.pmSymbol = "pm"
            } else {
                dateFormatter2.dateFormat = showingDataForMax10Days ? "EEE" : "MMM"
            }

            if safeLowerBound < safeUpperBound {
                context.setFillColor(UIColor.systemGreen.withAlphaComponent(0.15).cgColor)

                let lowerSafeYPos = height - ((CGFloat(safeLowerBound - minY) / CGFloat(maxY - minY)) * height) + topMargin
                let upperSafeYPos = height - ((CGFloat(safeUpperBound - minY) / CGFloat(maxY - minY)) * height) + topMargin

                let safeAreaRect = CGRect(x: margin, y: upperSafeYPos, width: rect.width - margin - rightMargin, height: lowerSafeYPos - upperSafeYPos)
                let safeAreaPath = UIBezierPath(roundedRect: safeAreaRect, cornerRadius: 8)
                context.addPath(safeAreaPath.cgPath)
                context.fillPath()
            }

            // Draw horizontal Y axis lines and labels
            for i in 1...9 {
                let yValue = minY + Double(i) * yAxisInterval
                if yValue >= 0 {
                    let yPos = height - ((CGFloat(yValue - minY) / CGFloat(maxY - minY)) * height) + topMargin
                    let yLabel = isPresentingTime ? yValue.toHoursMinutesString() : String(yValue.rounded(toPlaces: 1))

                    context.setLineWidth(1)
                    context.setStrokeColor(UIColor.secondaryLabel.withAlphaComponent(0.15).cgColor)
                    context.move(to: CGPoint(x: margin, y: yPos))
                    context.addLine(to: CGPoint(x: rect.width - rightMargin, y: yPos))
                    context.strokePath()

                    let yLabelAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                    let yLabelSize = yLabel.size(withAttributes: yLabelAttributes)
                    yLabel.draw(in: CGRect(x: rect.width - rightMargin + yLabelOffset, y: yPos - yLabelSize.height / 2, width: yLabelSize.width, height: yLabelSize.height), withAttributes: yLabelAttributes)
                }
            }

            // Draw vertical lines for each data point
            context.setLineWidth(1)
            context.setStrokeColor(UIColor.secondaryLabel.withAlphaComponent(0.1).cgColor)

            for index in 0..<filteredData.count {
                let xPos = margin + CGFloat(index) * width / CGFloat(filteredData.count - 1)
                context.move(to: CGPoint(x: xPos, y: topMargin))
                context.addLine(to: CGPoint(x: xPos, y: height + topMargin))
                context.strokePath()
            }

            // Draw graph line
            context.setLineWidth(2.5)
            context.setStrokeColor(UIColor.secondaryLabel.cgColor)

            for (index, dataPoint) in filteredData.enumerated() {
                let xPos = margin + CGFloat(index) * width / CGFloat(filteredData.count - 1)
                let yPos = height - ((CGFloat(dataPoint.y - minY) / CGFloat(maxY - minY)) * height) + topMargin

                if index == 0 {
                    context.move(to: CGPoint(x: xPos, y: yPos))
                } else {
                    context.addLine(to: CGPoint(x: xPos, y: yPos))
                }
            }

            context.strokePath()

            // Determine which x-labels to show
            let indicesToShow: [Int]
            if showingDataForMax10Days {
                indicesToShow = Array(0..<filteredData.count)
            } else {
                let maxDates = min(10, filteredData.count)
                indicesToShow = Array(stride(from: filteredData.count - 1, through: 0, by: -(filteredData.count / maxDates)))
            }

            let sortedIndicesToShow = indicesToShow.sorted()

            for index in sortedIndicesToShow {
                let dataPoint = filteredData[index]
                let xPos = margin + CGFloat(index) * width / CGFloat(filteredData.count - 1)
                let yPos = height - ((CGFloat(dataPoint.y - minY) / CGFloat(maxY - minY)) * height) + topMargin

                let xLabel1 = dateFormatter1.string(from: dataPoint.x)
                let xLabel2 = dateFormatter2.string(from: dataPoint.x)
                let xLabel = "\(xLabel1)\n\(xLabel2.capitalized)"

                let xLabelAttributes: [NSAttributedString.Key: Any] = [
                    .font: Calendar.current.isDate(dataPoint.x, inSameDayAs: .now) ? UIFont.systemFont(ofSize: 12, weight: .semibold) : UIFont.systemFont(ofSize: 10),
                    .foregroundColor: Calendar.current.isDate(dataPoint.x, inSameDayAs: .now) ? UIColor.label : UIColor.secondaryLabel
                ]
                let xLabelSize = xLabel.size(withAttributes: xLabelAttributes)
                xLabel.draw(in: CGRect(x: xPos - xLabelSize.width / 2, y: height + topMargin, width: xLabelSize.width, height: xLabelSize.height), withAttributes: xLabelAttributes)

                let circleRect = CGRect(x: xPos - 5, y: yPos - 5, width: 10, height: 10)
                if Calendar.current.isDate(dataPoint.x, inSameDayAs: .now) && !presentDataForOneDay {
                    context.setStrokeColor(UIColor.systemBlue.cgColor)
                    context.setLineWidth(4)
                } else {
                    context.setStrokeColor(UIColor.secondaryLabel.cgColor)
                    context.setLineWidth(2.5)
                }
                context.setFillColor(UIColor.systemBackground.cgColor)
                context.fillEllipse(in: circleRect)
                context.strokeEllipse(in: circleRect)
            }

            self.addTouchPoints()
        }
        
        
        private func addTouchPoints() {
            // Remove old touch points to avoid duplication
            self.subviews.filter { $0 is UIButton && $0 != loadingButton }.forEach { $0.removeFromSuperview() }
            
            guard filteredData.count > 1 else { return }
            
            let width = self.bounds.width - margin - rightMargin
            let height = self.bounds.height - topMargin - bottomMargin
            let buttonWidth = width / CGFloat(filteredData.count - 1) // Calculate width to cover entire area

            let yValues = filteredData.map { $0.y }
            var minY = yValues.min() ?? 0
            var maxY = yValues.max() ?? 0
            
            let yRange = maxY - minY
            minY -= yRange * 0.25
            maxY += yRange * 0.25
            
            for index in 0...filteredData.count - 1 {
                let xPos = margin + CGFloat(index) * width / CGFloat(filteredData.count - 1)
                
                // Adjust button frame to eliminate gaps and ensure coverage
                let touchButton = UIButton(frame: CGRect(x: xPos - buttonWidth / 2, y: topMargin, width: buttonWidth, height: height))
                touchButton.tag = index
                
                touchButton.addTarget(self, action: #selector(touchPointTapped(_:)), for: .touchUpInside)
                self.addSubview(touchButton)
            }
        }
        
        @objc private func touchPointTapped(_ sender: UIButton) {
//            if SubscriptionVC.isSubscriptionActive() {
//                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                let index = sender.tag
//                
//                if index == self.selectedIndex {
//                    // If the tapped point is the currently selected one, unselect it
//                    self.selectedIndex = nil
//                    self.selectedValue = nil
//                } else {
//                    // If a different point is tapped, select and show the value
//                    self.selectedIndex = index
//                    let dataPoint = filteredData[index]
//                    self.selectedValue = dataPoint
//                }
//            } else {
//                // Show subscription modal if not active
//                let subscriptionViewController = ThemeNavigationViewController(rootViewController: Subscription2VC())
//                subscriptionViewController.modalTransitionStyle = .crossDissolve
//                subscriptionViewController.modalPresentationStyle = .fullScreen
//                self.viewController?.present(subscriptionViewController, animated: true)
//            }
        }
    }
    
    
    //Data class
    struct GraphData {
        let x: Date
        let y: Double
    }

}
