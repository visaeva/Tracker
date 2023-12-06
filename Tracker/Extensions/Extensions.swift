//
//  Extensions.swift
//  Tracker
//
//  Created by Victoria Isaeva on 20.10.2023.
//

import UIKit

// MARK: Date
extension Date {
    func deleteTime() -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components)
    }
}

// MARK: UIColor
extension UIColor {
    static var darkBackground: UIColor { UIColor(named: "Background") ?? .clear }
    static var lightBackground: UIColor { UIColor(named: "BackgroundGray") ?? .clear }
    static var blue: UIColor { UIColor(named: "Blue") ?? .clear }
    static var backgroundDark: UIColor { UIColor(named: "backgroundDark") ?? .clear }
    static var mainColor: UIColor { UIColor(named: "mainColor") ?? .clear}
}

