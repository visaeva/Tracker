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
