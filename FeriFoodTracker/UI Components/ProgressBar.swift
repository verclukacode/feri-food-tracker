//
//  ProgressBar.swift
//  Citrus
//
//  Created by Luka Verč on 5. 7. 24.
//

import UIKit

class ProgressBar: UIView {
    
    //Data
    public var value: Double = 0
    
    public var barColor: UIColor{
        get {
            return self.line.backgroundColor ?? .systemBlue
        } set (newValue) {
            self.line.backgroundColor = newValue
        }
    }
    
    public var backColor: UIColor{
        get {
            return self.backgroundColor ?? .secondarySystemBackground
        } set (newValue) {
            self.backgroundColor = newValue
        }
    }
    
    
    //UI
    private let line = UIView()
    public let lineGlow = UIView()
    

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.frame.height / 2
        
        line.frame = CGRect(x: 0, y: 0, width: value == 0 ? 0 : max(self.frame.width * value, self.frame.height * 0.3), height: self.frame.height)
        line.layer.cornerRadius = self.frame.height / 2
        
        if self.frame.width * value > 45 {
            lineGlow.frame = CGRect(x: 25, y: 4, width: (self.frame.width * min(value, 1)) - 40, height: 6)
        } else {
            lineGlow.frame = .zero
        }
        
        lineGlow.layer.cornerRadius = lineGlow.frame.height / 2
        
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerCurve = .continuous
        self.clipsToBounds = true
        self.backgroundColor = .secondarySystemBackground
        
        
        line.layer.cornerCurve = .continuous
        line.backgroundColor = self.barColor
        self.addSubview(line)
        
        lineGlow.layer.cornerCurve = .continuous
        lineGlow.backgroundColor = .white.withAlphaComponent(0.15)
        self.addSubview(lineGlow)
        
    }
    
    public func setUp(with value: Double, color: UIColor, animated: Bool = false) {
        self.value = value
        self.barColor = color
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut) {
                self.layoutSubviews()
            }
        } else {
            self.layoutSubviews()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
