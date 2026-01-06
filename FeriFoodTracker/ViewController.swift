//
//  ViewController.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 7. 11. 25.
//

import UIKit

final class CalorieRingView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    var progress: CGFloat = 0 {
        didSet {
            let clamped = max(0, min(progress, 1))
            progressLayer.strokeEnd = clamped
        }
    }

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

        let path = UIBezierPath(
            arcCenter: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

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

final class MacroStatView: UIView {

    let titleLabel = UILabel()
    let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.label.withAlphaComponent(0.6)
        layer.cornerRadius = 16
        layer.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .systemBackground

        valueLabel.font = .systemFont(ofSize: 18, weight: .medium)
        valueLabel.textColor = .systemBackground

        addSubview(titleLabel)
        addSubview(valueLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()

        let padding: CGFloat = 12
        titleLabel.frame = CGRect(x: padding, y: 10, width: bounds.width - padding * 2, height: 16)
        valueLabel.frame = CGRect(x: padding, y: titleLabel.frame.maxY + 4, width: bounds.width - padding * 2, height: 22)
    }
}

final class ViewController: UIViewController, ScanEANViewControllerDelegate {

    static var selectedDate: Date = .now
    static var activeObject: ViewController?

    let gradientBackView = PastelGradientView()

    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        if #available(iOS 13.4, *) { p.preferredDatePickerStyle = .compact }
        p.tintColor = .label
        p.contentHorizontalAlignment = .center
        return p
    }()

    private let settingsButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        b.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: config), for: .normal)
        b.tintColor = .label
        b.backgroundColor = UIColor.label.withAlphaComponent(0.15)
        b.layer.cornerRadius = 18
        b.layer.cornerCurve = .continuous
        return b
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

    private let backView: UIView = {
        let v = UIView()
        v.backgroundColor = .label.withAlphaComponent(0.05)
        return v
    }()

    private let viewEntriesButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(" Entries", for: .normal)
        b.setImage(UIImage(systemName: "note.text")?.withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14))), for: .normal)
        b.tintColor = .label
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.setTitleColor(.label, for: .normal)
        b.backgroundColor = UIColor.label.withAlphaComponent(0.15)
        b.layer.cornerRadius = 16
        return b
    }()

    private let viewSuggestionsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(" Suggestions", for: .normal)
        b.setImage(UIImage(systemName: "sparkles.2")?.withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14))), for: .normal)
        b.tintColor = .label
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
        b.tintColor = .systemBackground
        b.layer.cornerRadius = 35
        b.clipsToBounds = true
        return b
    }()

    private let carbsView: MacroStatView = {
        let v = MacroStatView()
        v.titleLabel.text = "Carbs"
        return v
    }()

    private let proteinView: MacroStatView = {
        let v = MacroStatView()
        v.titleLabel.text = "Protein"
        return v
    }()

    private let fatView: MacroStatView = {
        let v = MacroStatView()
        v.titleLabel.text = "Fat"
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewController.activeObject = self

        CloudManager.shared.persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer

        view.addSubview(gradientBackView)
        view.addSubview(datePicker)
        view.addSubview(settingsButton)

        backView.layer.cornerRadius = 24
        backView.layer.cornerCurve = .continuous
        view.addSubview(backView)

        view.addSubview(ringView)
        view.addSubview(caloriesLabel)
        view.addSubview(carbsView)
        view.addSubview(proteinView)
        view.addSubview(fatView)
        view.addSubview(viewEntriesButton)
        view.addSubview(viewSuggestionsButton)
        view.addSubview(addButton)

        datePicker.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            ViewController.selectedDate = self.datePicker.date
            ViewController.activeObject?.refresh()
        }), for: .valueChanged)
        datePicker.date = ViewController.selectedDate

        settingsButton.addAction(UIAction(handler: { _ in
            self.present(UINavigationController(rootViewController: SettingsViewController()), animated: true)
        }), for: .touchUpInside)

        viewEntriesButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.present(UINavigationController(rootViewController: EntriesViewController() {
                self.refresh()
            }), animated: true)
        }), for: .touchUpInside)
        
        viewSuggestionsButton.addAction(UIAction(handler: { _ in
            
            let vc = UINavigationController(rootViewController: SuggestionsViewController())
            self.present(vc, animated: true)
            
        }), for: .touchUpInside)

        addButton.configuration = .glass()
        addButton.menu = UIMenu(children: [
            UIAction(title: "Browse food", image: UIImage(systemName: "magnifyingglass"), handler: { [weak self] _ in
                guard let self else { return }
                let viewController = LogFoodBrowseViewController(selectedDate: ViewController.selectedDate) {
                    self.refresh()
                }
                self.present(UINavigationController(rootViewController: viewController), animated: true)
            }),
            UIAction(title: "Scan barcode", image: UIImage(systemName: "barcode.viewfinder"), handler: { [weak self] _ in
                guard let self else { return }
                let viewController = ScanEANViewController()
                viewController.delegate = self
                self.present(UINavigationController(rootViewController: viewController), animated: true)
            }),
        ])
        addButton.showsMenuAsPrimaryAction = true

        refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        gradientBackView.frame = view.bounds

        let bounds = view.bounds
        let inset = view.safeAreaInsets
        let width = bounds.width
        let height = bounds.height

        datePicker.sizeToFit()
        datePicker.frame = CGRect(
            x: 0,
            y: inset.top + 12,
            width: view.frame.width,
            height: datePicker.bounds.height
        )

        let settingsSize: CGFloat = 36
        settingsButton.frame = CGRect(
            x: width - 15 - settingsSize,
            y: inset.top + 10,
            width: settingsSize,
            height: settingsSize
        )

        caloriesLabel.frame = CGRect(
            x: (view.frame.width - 120) / 2,
            y: height * 0.40 - 120 / 2,
            width: 120,
            height: 120
        )

        let ringSize = max(caloriesLabel.frame.width, caloriesLabel.frame.height) * 1.9
        ringView.frame = CGRect(
            x: caloriesLabel.center.x - ringSize / 2,
            y: caloriesLabel.center.y - ringSize / 2,
            width: ringSize,
            height: ringSize
        )

        let addButtonSize: CGFloat = 70
        let buttonY = height - inset.bottom - 24 - 60
        addButton.frame = CGRect(
            x: (width - addButtonSize) / 2,
            y: buttonY - 5,
            width: addButtonSize,
            height: addButtonSize
        )

        let cardHeight: CGFloat = 80
        let padding: CGFloat = 20
        let spacing: CGFloat = 12

        let totalWidth = width - padding * 2
        let cardWidth = (totalWidth - spacing * 2) / 3

        let cardY = addButton.frame.minY - 12 - cardHeight - 15

        carbsView.frame = CGRect(x: padding, y: cardY, width: cardWidth, height: cardHeight)
        proteinView.frame = CGRect(x: carbsView.frame.maxX + spacing, y: cardY, width: cardWidth, height: cardHeight)
        fatView.frame = CGRect(x: proteinView.frame.maxX + spacing, y: cardY, width: cardWidth, height: cardHeight)

        viewEntriesButton.frame = CGRect(
            x: padding,
            y: cardY - 60,
            width: (view.frame.width - 2 * padding - spacing) / 2,
            height: 45
        )

        viewSuggestionsButton.frame = CGRect(
            x: viewEntriesButton.frame.maxX + spacing,
            y: cardY - 60,
            width: (view.frame.width - 2 * padding - spacing) / 2,
            height: 45
        )

        backView.frame = CGRect(
            x: 0,
            y: viewSuggestionsButton.frame.minY - 30,
            width: view.frame.width,
            height: (view.frame.height - viewSuggestionsButton.frame.minY - 30 + view.safeAreaInsets.bottom + 100)
        )
    }

    func scanEANViewController(_ viewController: ScanEANViewController, didDetectEAN code: String) {
        viewController.dismiss(animated: true) {
            Task { [weak self] in
                guard let self else { return }
                if let food = try await APIManager.shared.fetchFoodData(fromEAN: code) {
                    let page = LogFoodViewController(food: food) {
                        self.refresh()
                    }
                    self.present(UINavigationController(rootViewController: page), animated: true)
                } else {
                    let alert = UIAlertController(title: "Something went wrong...", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Done", style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

extension ViewController {

    func refresh() {
        CloudManager.shared.getAll(for: ViewController.selectedDate) { [weak self] foodLogs in
            guard let self else { return }

            var calories: Double = 0
            var carbs: Double = 0
            var proteins: Double = 0
            var fats: Double = 0

            for foodLog in foodLogs {
                calories += foodLog.calories
                carbs += foodLog.carbs
                proteins += foodLog.protein
                fats += foodLog.fat
            }

            DispatchQueue.main.async {
                self.caloriesLabel.text = "\(Int(calories))"
                self.ringView.setProgress(calories / UserData.shared.goalCalories, animated: true)
                self.carbsView.valueLabel.text = "\(Int(carbs)) g"
                self.proteinView.valueLabel.text = "\(Int(proteins)) g"
                self.fatView.valueLabel.text = "\(Int(fats)) g"
            }
        }
    }
}
