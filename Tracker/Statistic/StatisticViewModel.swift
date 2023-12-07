//
//  StatisticViewModel.swift
//  Tracker
//
//  Created by Victoria Isaeva on 25.11.2023.
//

import Foundation

final class StatisticViewModel {
    var onTrackersChange: (([TrackerRecord]) -> Void)?
    
    private let trackerRecordStore = TrackerRecordStore()
    private var trackers: [TrackerRecord] = [] {
        didSet {
            onTrackersChange?(trackers)
        }
    }
    
    func viewWillAppear() {
        guard let trackers = try? trackerRecordStore.loadCompletedTrackers() else {
            return
        }
        self.trackers = trackers
    }
}
