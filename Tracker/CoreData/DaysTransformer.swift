//
//  DaysTransformer.swift
//  Tracker
//
//  Created by Victoria Isaeva on 07.10.2023.
//

import Foundation

struct DaysTransformer {
    func convertSetToMyScheduleString(_ set: Set<WeekDay>) -> String {
        let dayStrings = set.map { String($0.rawValue) }
        return dayStrings.joined(separator: ",")
    }
    
    func convertMyScheduleStringToSet(_ string: String) -> Set<WeekDay> {
        let components = string.split(separator: ",").compactMap { Int($0) }
        let weekdays = components.compactMap { WeekDay(rawValue: $0) }
        return Set(weekdays)
    }
}
