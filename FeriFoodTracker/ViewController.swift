//
//  ViewController.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 7. 11. 25.
//

import UIKit

// MARK: - Ring View

final class CalorieRingView: UIView {
    
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    /// 0.0 – 1.0
    var progress: CGFloat = 0 {
        didSet {
            let clamped = max(0, min(progress, 1))
            progressLayer.strokeEnd = clamped
        }
    }
    
    /// Thickness of the ring
    var lineWidth: CGFloat = 14 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        trackLayer.strokeColor = UIColor.label.withAlphaComponent(0.3).cgColor
        progressLayer.strokeColor = UIColor.label.withAlphaComponent(0.6).cgColor
        
        let size = min(bounds.width, bounds.height)
        let rect = CGRect(
            x: (bounds.width - size) / 2,
            y: (bounds.height - size) / 2,
            width: size,
            height: size
        ).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let path = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY),
                                radius: rect.width / 2,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        
        trackLayer.frame = bounds
        progressLayer.frame = bounds
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
    
    func setProgress(_ value: CGFloat, animated: Bool, duration: CFTimeInterval = 0.5) {
        let clamped = max(0, min(value, 1))
        
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clamped
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.add(animation, forKey: "strokeEnd")
        }
        
        progressLayer.strokeEnd = clamped
        progress = clamped
    }
}

// MARK: - MacroStatView

final class MacroStatView: UIView {
    
    let titleLabel = UILabel()
    let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.label.withAlphaComponent(0.15)
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .label
        
        valueLabel.font = .systemFont(ofSize: 18, weight: .medium)
        valueLabel.textColor = .label
        
        addSubview(titleLabel)
        addSubview(valueLabel)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding: CGFloat = 12
        titleLabel.frame = CGRect(x: padding, y: 10,
                                  width: bounds.width - padding*2, height: 16)
        valueLabel.frame = CGRect(x: padding,
                                  y: titleLabel.frame.maxY + 4,
                                  width: bounds.width - padding*2, height: 22)
    }
}

// MARK: - ViewController

class ViewController: UIViewController {
    
    let gradientBackView = PastelGradientView()
    
    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        if #available(iOS 13.4, *) { p.preferredDatePickerStyle = .compact }
        p.tintColor = .label
        p.contentHorizontalAlignment = .center
        return p
    }()
    
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.text = "2314"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 40, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let ringView = CalorieRingView()
    
    private let viewEntriesButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("View entries", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.setTitleColor(.label, for: .normal)
        b.backgroundColor = UIColor.label.withAlphaComponent(0.15)
        b.layer.cornerRadius = 16
        return b
    }()
    
    // NEW: View suggestions button
    private let viewSuggestionsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("View suggestions", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.setTitleColor(.label, for: .normal)
        b.backgroundColor = UIColor.label.withAlphaComponent(0.15)
        b.layer.cornerRadius = 16
        return b
    }()
    
    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        b.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        b.tintColor = .label
        b.backgroundColor = UIColor.label.withAlphaComponent(0.15)
        b.layer.cornerRadius = 35
        b.clipsToBounds = true
        return b
    }()
    
    private let carbsView: MacroStatView = {
        let v = MacroStatView()
        v.titleLabel.text = "Carbs"
        v.valueLabel.text = "210 g"
        return v
    }()
    
    private let proteinView: MacroStatView = {
        let v = MacroStatView()
        v.titleLabel.text = "Protein"
        v.valueLabel.text = "145 g"
        return v
    }()
    
    private let fatView: MacroStatView = {
        let v = MacroStatView()
        v.titleLabel.text = "Fat"
        v.valueLabel.text = "78 g"
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(gradientBackView)
        view.addSubview(datePicker)
        view.addSubview(ringView)
        view.addSubview(caloriesLabel)
        view.addSubview(carbsView)
        view.addSubview(proteinView)
        view.addSubview(fatView)
        view.addSubview(viewEntriesButton)
        view.addSubview(viewSuggestionsButton)   // NEW
        view.addSubview(addButton)
        
        // Example: 65% of daily goal
        ringView.setProgress(0.65, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientBackView.frame = view.bounds
        
        let bounds = view.bounds
        let inset = view.safeAreaInsets
        let width = bounds.width
        let height = bounds.height
        
        // Date picker (top)
        datePicker.sizeToFit()
        datePicker.frame = CGRect(
            x: 0,
            y: inset.top + 12,
            width: view.frame.width,
            height: datePicker.bounds.height
        )
        
        // Calories label centered
        caloriesLabel.frame = CGRect(
            x: 20,
            y: height * 0.40 - 24,
            width: width - 40,
            height: 1000
        )
        caloriesLabel.sizeToFit()
        caloriesLabel.frame = CGRect(
            x: (width - caloriesLabel.frame.width) / 2,
            y: height * 0.40 - (caloriesLabel.frame.height / 2),
            width: caloriesLabel.frame.width,
            height: caloriesLabel.frame.height
        )
        
        // Ring around calories label
        let ringSize = max(caloriesLabel.frame.width, caloriesLabel.frame.height) * 1.9
        ringView.frame = CGRect(
            x: caloriesLabel.center.x - ringSize / 2,
            y: caloriesLabel.center.y - ringSize / 2,
            width: ringSize,
            height: ringSize
        )
        
        // Bottom buttons (Add circle + View entries)
        let buttonY = height - inset.bottom - 24 - 60
        
        let addButtonSize: CGFloat = 70
        addButton.frame = CGRect(
            x: width - 20 - addButtonSize,
            y: buttonY - 5,
            width: addButtonSize,
            height: addButtonSize
        )
        
        viewEntriesButton.sizeToFit()
        let veSize = viewEntriesButton.bounds.size
        
        viewEntriesButton.frame = CGRect(
            x: 20,
            y: buttonY,
            width: veSize.width + 30,
            height: veSize.height + 6
        )
        
        // NEW: View suggestions button under View entries
        viewSuggestionsButton.sizeToFit()
        let vsSize = viewSuggestionsButton.bounds.size
        
        viewSuggestionsButton.frame = CGRect(
            x: 20,
            y: viewEntriesButton.frame.maxY + 10,
            width: vsSize.width + 30,
            height: vsSize.height + 6
        )
        
        // Macro boxes above the *top* button row (View entries)
        let cardHeight: CGFloat = 80
        let padding: CGFloat = 20
        let spacing: CGFloat = 12
        
        let totalWidth = width - padding * 2
        let cardWidth = (totalWidth - spacing * 2) / 3
        
        let cardY = viewEntriesButton.frame.minY - 20 - cardHeight
        
        carbsView.frame = CGRect(x: padding, y: cardY, width: cardWidth, height: cardHeight)
        proteinView.frame = CGRect(x: carbsView.frame.maxX + spacing, y: cardY, width: cardWidth, height: cardHeight)
        fatView.frame = CGRect(x: proteinView.frame.maxX + spacing, y: cardY, width: cardWidth, height: cardHeight)
    }
}
