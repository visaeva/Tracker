//
//  TrackerStruct.swift
//  Tracker
//
//  Created by Victoria Isaeva on 26.09.2023.
//

import UIKit

struct TrackerCellViewModel {
    let name: String
    let emoji: String
    let color: UIColor?
    var trackerIsDone: Bool
    let doneButtonIsEnabled: Bool
    var counter: UInt
    let id: UUID
}
