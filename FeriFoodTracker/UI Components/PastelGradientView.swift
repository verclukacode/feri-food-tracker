//
//  PastelGradientView.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 3. 12. 25.
//


import UIKit

final class PastelGradientView: UIView {
    
    // MARK: - Properties
    
    private let gradientLayer = CAGradientLayer()
    
    /// How long one full color transition takes (seconds)
    var colorAnimationDuration: CFTimeInterval = 5.0
    
    /// How long it takes the gradient to “shift” across the view
    var positionAnimationDuration: CFTimeInterval = 12.0
    
    /// Light-mode pastel color sets
    private let pastelColorSetsLight: [[CGColor]] = [
        [
            UIColor(red: 0.95, green: 0.90, blue: 1.00, alpha: 1.0).cgColor, // soft lavender
            UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1.0).cgColor  // soft baby blue
        ],
        [
            UIColor(red: 0.96, green: 0.94, blue: 0.99, alpha: 1.0).cgColor, // lilac
            UIColor(red: 0.96, green: 0.98, blue: 0.92, alpha: 1.0).cgColor  // pale mint
        ],
        [
            UIColor(red: 1.00, green: 0.95, blue: 0.95, alpha: 1.0).cgColor, // blush
            UIColor(red: 0.94, green: 0.98, blue: 1.00, alpha: 1.0).cgColor  // ice blue
        ],
        [
            UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0).cgColor, // cream
            UIColor(red: 0.94, green: 0.96, blue: 1.00, alpha: 1.0).cgColor  // pastel periwinkle
        ]
    ]
    
    /// Dark-mode pastel color sets (slightly deeper but still soft)
    private let pastelColorSetsDark: [[CGColor]] = [
        [
            UIColor(red: 0.32, green: 0.29, blue: 0.45, alpha: 1.0).cgColor, // muted lavender
            UIColor(red: 0.25, green: 0.34, blue: 0.45, alpha: 1.0).cgColor  // muted blue
        ],
        [
            UIColor(red: 0.34, green: 0.30, blue: 0.42, alpha: 1.0).cgColor, // deep lilac
            UIColor(red: 0.26, green: 0.38, blue: 0.34, alpha: 1.0).cgColor  // soft teal
        ],
        [
            UIColor(red: 0.39, green: 0.29, blue: 0.33, alpha: 1.0).cgColor, // dusty rose
            UIColor(red: 0.26, green: 0.36, blue: 0.46, alpha: 1.0).cgColor  // dusk blue
        ],
        [
            UIColor(red: 0.33, green: 0.30, blue: 0.29, alpha: 1.0).cgColor, // warm gray
            UIColor(red: 0.28, green: 0.33, blue: 0.44, alpha: 1.0).cgColor  // indigo-ish
        ]
    ]
    
    /// The palette that should be used for the current interface style
    private var currentColorSets: [[CGColor]] {
        if traitCollection.userInterfaceStyle == .dark {
            return pastelColorSetsDark
        } else {
            return pastelColorSetsLight
        }
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        isUserInteractionEnabled = false   // purely decorative background
        setupGradientLayer()
        applyCurrentBaseColors()
        startAnimating()
    }
    
    private func setupGradientLayer() {
        gradientLayer.type = .axial
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.locations  = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func applyCurrentBaseColors() {
        gradientLayer.colors = currentColorSets.first
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    // MARK: - Trait changes (Light / Dark mode)
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            return
        }
        
        // When switching light/dark mode:
        // - Update the base colors
        // - Restart animations so they use the new palette
        stopAnimating()
        applyCurrentBaseColors()
        startAnimating()
    }
    
    // MARK: - Animation
    
    func startAnimating() {
        animateColors()
        animatePosition()
    }
    
    private func animateColors() {
        // Build a looping sequence of color sets for the current appearance
        var allColors: [[CGColor]] = []
        let palettes = currentColorSets
        
        allColors.append(contentsOf: palettes)
        
        // To loop seamlessly, end at the first set again
        if let first = palettes.first {
            allColors.append(first)
        }
        
        let animation = CAKeyframeAnimation(keyPath: "colors")
        animation.values = allColors
        animation.duration = colorAnimationDuration
        animation.calculationMode = .linear
        animation.autoreverses = false
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.add(animation, forKey: "pastelColorChange")
    }
    
    private func animatePosition() {
        // Subtle movement of startPoint and endPoint
        let startAnimation = CAKeyframeAnimation(keyPath: "startPoint")
        startAnimation.values = [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 0.1, y: 0.0),
            CGPoint(x: 0.0, y: 0.1),
            CGPoint(x: 0.0, y: 0.0)
        ].map { NSValue(cgPoint: $0) }
        
        startAnimation.duration = positionAnimationDuration
        startAnimation.calculationMode = .linear
        startAnimation.autoreverses = false
        startAnimation.repeatCount = .infinity
        startAnimation.isRemovedOnCompletion = false
        startAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let endAnimation = CAKeyframeAnimation(keyPath: "endPoint")
        endAnimation.values = [
            CGPoint(x: 1.0, y: 1.0),
            CGPoint(x: 0.9, y: 1.0),
            CGPoint(x: 1.0, y: 0.9),
            CGPoint(x: 1.0, y: 1.0)
        ].map { NSValue(cgPoint: $0) }
        
        endAnimation.duration = positionAnimationDuration
        endAnimation.calculationMode = .linear
        endAnimation.autoreverses = false
        endAnimation.repeatCount = .infinity
        endAnimation.isRemovedOnCompletion = false
        endAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.add(startAnimation, forKey: "gradientStartMovement")
        gradientLayer.add(endAnimation, forKey: "gradientEndMovement")
    }
    
    func stopAnimating() {
        gradientLayer.removeAllAnimations()
    }
}
