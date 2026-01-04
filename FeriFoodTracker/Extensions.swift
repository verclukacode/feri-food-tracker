//
//  Extensions.swift
//  Citrus
//
//  Created by Luka Verč on 4. 7. 24.
//

import UIKit
internal import HealthKit


extension TimeInterval {
    func toHoursMinutesString() -> String {
        if self.isNaN || self == 0 {
            return "0min"
        }
        
        let minutes = (Int(self) / 60) % 60
        let hours = Int(self) / 3600
        
        if hours > 0 {
            return String(format: "%dh %dmin", hours, minutes)
        } else {
            return String(format: "%dmin", minutes)
        }
    }
}


extension Date {
    // Helper function to get the ordinal suffix for the day
    private func ordinalSuffix(from day: Int) -> String {
        switch day {
        case 11, 12, 13:
            return "th"
        default:
            switch day % 10 {
            case 1:
                return "st"
            case 2:
                return "nd"
            case 3:
                return "rd"
            default:
                return "th"
            }
        }
    }
    
    // Function to format the date
    func displayString() -> String {
        
//        if Calendar.current.isDateInToday(self) {
//            return "Today"
//        } else if Calendar.current.isDateInTomorrow(self) {
//            return "Tomorrow"
//        } else if Calendar.current.isDateInYesterday(self) {
//            return "Yesterday"
//        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d MMMM, yyyy"
        
        // Get the day component
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        
        // Format the date
        var dateString = dateFormatter.string(from: self)
        
        // Find the day in the formatted string and add the ordinal suffix
        if let dayRange = dateString.range(of: "\(day)") {
            let suffix = ordinalSuffix(from: day)
            dateString.replaceSubrange(dayRange, with: "\(day)\(suffix)")
        }
        
        return dateString
    }
    
    var abbreviatedDayName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E" // "E" stands for the abbreviated day name (Mon, Tue, Wed, etc.)
        return dateFormatter.string(from: self)
    }
}


extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


extension Date {
    func daysBetween(end: Date) -> Int {
        let calendar = Calendar.current
        
        // Ensure the dates are in the same day component
        let startOfDay = calendar.startOfDay(for: self)
        let endOfDay = calendar.startOfDay(for: end)
        
        // Calculate the difference in days
        let components = calendar.dateComponents([.day], from: startOfDay, to: endOfDay)
        return components.day ?? 1
    }
    
    // Function to get the start and end of the current week
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }
    
    func endOfWeek() -> Date {
        return Calendar.current.date(byAdding: .day, value: 6, to: self.startOfWeek())!
    }
}


extension Int {
    func closestSmallerMultiple(of factor: Int) -> Int {
        guard factor != 0 else { return 0 }  // Prevent division by zero
        return Int(floor(Double(self) / Double(factor)) * Double(factor))
    }
}


extension String {

   func localized(withTable: String = "Yoa") -> String {
       return NSLocalizedString(self, tableName: "Localizable", bundle: Bundle.main, value: "", comment: "")
   }

}


extension Date {
    func toOrdinalDateString() -> String {
        
        if Calendar.current.isDateInToday(self) {
            return "Today".localized()
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let dateYear = Calendar.current.component(.year, from: self)
        
        let dateFormatter = DateFormatter()
        
        // Check if the date is in the current year
        if currentYear == dateYear {
            dateFormatter.dateFormat = "MMMM"
        } else {
            dateFormatter.dateFormat = "MMMM yyyy"
        }
        
        let day = Calendar.current.component(.day, from: self)
        let monthYear = dateFormatter.string(from: self)
        
        return "\(day)\(day.ordinalSuffix()) \(monthYear)"
    }
    
    
    func toHoursMinutesString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self)
    }
}

extension Int {
    func ordinalSuffix() -> String {
        let suffixes = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"]
        let ones = self % 10
        let tens = (self / 10) % 10

        if tens == 1 {
            return "th"
        } else {
            return suffixes[ones]
        }
    }
}


extension Double {
    func fitnessContributionStage() -> String {
        switch self {
        case 0..<0.10:
            return "Minimal".localized()
        case 0.10..<0.25:
            return "Low".localized()
        case 0.25..<0.40:
            return "Moderate".localized()
        case 0.40..<0.60:
            return "High".localized()
        case 0.60...0.80:
            return "Very High".localized()
        case 0.80...:
            return "Crazy High".localized()
        default:
            return "- -"
        }
    }
}


extension Array where Element == Double {
    func average() -> Double {
        return self.isEmpty ? 0.0 : self.reduce(0, +) / Double(self.count)
    }
}

extension HKQuantityTypeIdentifier {
    var associatedUnit: HKUnit {
        switch self {

        case .dietaryIron, .dietaryZinc, .dietaryBiotin, .dietaryCopper, .dietaryFolate,
             .dietaryIodine, .dietaryNiacin, .dietaryCalcium, .dietaryThiamin,
             .dietaryCaffeine, .dietaryChromium, .dietaryMagnesium, .dietaryVitaminA,
             .dietaryVitaminB6, .dietaryVitaminB12, .dietaryVitaminC, .dietaryVitaminD,
             .dietaryVitaminE, .dietaryVitaminK:
            return .gramUnit(with: .milli)

        case .numberOfAlcoholicBeverages:
            return .count()

        default:
            return .count()
        }
    }
}


extension Double {
    func getBasicYoaForSleepScore() -> String {
        if self < 0.6 {
            return "Dead1"
        } else if self < 0.7 {
            return "Tired1"
        } else if self < 0.8 {
            return "Rested1"
        } else {
            return "Energetic2"
        }
    }
}


extension UIViewController {
    func alert(title: String, description: String? = nil) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done".localized(), style: .cancel))
        self.present(alert, animated: true)
    }
    
    @objc
    func onClose() {
        self.dismiss(animated: true)
    }
}


extension UIView {
    
    func shineEffect() {
        weak let weakView = self
        
        let animationDuration: Double = 0.9
        let animationGapDuration: Double = 5
        
        func shimmerOnce() {
            guard let v = weakView else { return }
            
            let borderView = UIView()
            borderView.isUserInteractionEnabled = false
            borderView.isHidden = true
            
            borderView.frame = self.bounds
            borderView.layer.cornerRadius = self.layer.cornerRadius
            borderView.layer.cornerCurve = self.layer.cornerCurve
            borderView.layer.borderWidth = 2.5
            borderView.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
            borderView.alpha = 0
            self.addSubview(borderView)

            // Create shimmer gradient
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor.clear.cgColor,
                UIColor.white.withAlphaComponent(0.33).cgColor,
                UIColor.clear.cgColor
            ]
            gradient.locations = [0, 0.5, 1]

            gradient.startPoint = CGPoint(x: 0.0, y: 0.605)   // left side slightly lower
            gradient.endPoint   = CGPoint(x: 1.0, y: 0.395)   // right side slightly higher

            gradient.frame = v.bounds

            // Start just off-screen on the left
            gradient.transform = CATransform3DMakeTranslation(-v.bounds.width, 0, 0)
            v.layer.addSublayer(gradient)

            // Animate across the view
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                // Remove shimmer immediately once it reaches right edge
                gradient.removeFromSuperlayer()
                
                // Loop every 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + animationGapDuration) {
                    shimmerOnce()
                }
            }

            let anim = CABasicAnimation(keyPath: "transform.translation.x")
            anim.fromValue = -v.bounds.width
            anim.toValue = v.bounds.width
            anim.duration = animationDuration
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.fillMode = .forwards
            anim.isRemovedOnCompletion = false

            gradient.add(anim, forKey: "shimmer")
            CATransaction.commit()
            
            borderView.isHidden = false
            UIView.animate(withDuration: animationDuration * 0.20, delay: 0, options: .curveEaseIn) {
                borderView.alpha = 1
            } completion: { _ in
                UIView.animate(withDuration: animationDuration * 0.60, delay: 0, options: .curveEaseOut) {
                    borderView.alpha = 0
                } completion: { _ in
                    borderView.isHidden = true
                    borderView.removeFromSuperview()
                }
            }
        }
        
        shimmerOnce()
    }
    
}


extension UIColor {
    
    var forGlassBackground: UIColor {
        if #available(iOS 26.0, *) {
            return self.withAlphaComponent(0.5)
        } else {
            return self
        }
    }
    
}
