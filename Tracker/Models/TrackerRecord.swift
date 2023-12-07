//
//  TrackerRecord.swift
//  Tracker
//
//  Created by Victoria Isaeva on 26.09.2023.
//

import Foundation

struct TrackerRecord: Hashable, Equatable, Codable {
    let id: UUID
    let date: Date
}
