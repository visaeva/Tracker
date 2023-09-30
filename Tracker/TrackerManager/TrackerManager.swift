//
//  TrackerManager.swift
//  Tracker
//
//  Created by Victoria Isaeva on 29.09.2023.
//

import Foundation

struct CompletedTracker {
    let trackerId: UUID
    let date: Date
}

class TrackerManager {
    static let shared = TrackerManager()
    private var completedTrackers: [CompletedTracker] = []
    
    // MARK: - Public Methods
    func markTrackerAsCompleted(trackerId: UUID, date: Date) {
        let completedTracker = CompletedTracker(trackerId: trackerId, date: date)
        completedTrackers.append(completedTracker)
    }
    
    func isTrackerCompleted(trackerId: UUID, date: Date) -> Bool {
        return completedTrackers.contains { $0.trackerId == trackerId && Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func getCompletionCount(for trackerId: UUID) -> Int {
        return completedTrackers.filter { $0.trackerId == trackerId }.count
    }
    
    func decreaseCompletionCount(trackerId: UUID, date: Date) {
        if let index = completedTrackers.firstIndex(where: { $0.trackerId == trackerId && Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            completedTrackers.remove(at: index)
        }
    }
    
    func clearCompletedTrackers() {
        completedTrackers.removeAll()
    }
}
