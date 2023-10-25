//
//  TrackerRecordStore.swift
//  Tracker
//
//  Created by Victoria Isaeva on 07.10.2023.
//

import UIKit
import CoreData

final class TrackerRecordStore: NSObject {
    
    // MARK: Public Properties
    let trackerStore = TrackerStore()
    var trackerRecords: [TrackerRecord]? {
        try? fetchedResultController.performFetch()
        guard let objects = fetchedResultController.fetchedObjects,
              let trackerRecords = try? objects.map({ try makeTrackerRecord(from: $0) })
        else { return [] }
        return trackerRecords
    }
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext
    private lazy var fetchedResultController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let request = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
        request.sortDescriptors = []
        let controller = NSFetchedResultsController(fetchRequest: request,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        do {
            try controller.performFetch()
        } catch {
            print(error.localizedDescription)
        }
        
        return controller
    }()
    
    // MARK: - Initializers
    convenience override init() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            self.init(context: context)
        } else {
            fatalError("Unable to access the AppDelegate")
        }
    }
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
    }
    
    // MARK: - Public Methods
    func makeTrackerRecord(from trackerRecordsCoreData: TrackerRecordCoreData) throws -> TrackerRecord {
        guard let id = trackerRecordsCoreData.trackerid,
              let date = trackerRecordsCoreData.date
        else { throw TrackerStoreError.error }
        return TrackerRecord(id: id, date: date)
    }
    
    func createTrackerRecord(from trackerRecord: TrackerRecord) throws -> TrackerRecordCoreData {
        let trackerRecordCoreData = TrackerRecordCoreData(context: context)
        trackerRecordCoreData.populate(from: trackerRecord)
        saveContext()
        return trackerRecordCoreData
    }
    
    func deleteTrackerRecord(_ record: TrackerRecord) {
        deleteTrackerRecord(trackerId: record.id, date: record.date)
    }
    
    func deleteTrackerRecord(trackerId: UUID, date: Date) {
        let request = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
        request.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                        #keyPath(TrackerRecordCoreData.trackerid),
                                        trackerId.uuidString,
                                        #keyPath(TrackerRecordCoreData.date),
                                        date as CVarArg)
        guard let trackerRecords = try? context.fetch(request) else {
            assertionFailure("Failed to fetch(request)")
            return
        }
        if let trackerRecordDelete = trackerRecords.first {
            context.delete(trackerRecordDelete)
            saveContext()
        }
    }
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            let error = error as NSError
            assertionFailure("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    func getCompletionCount(for trackerId: UUID) -> Int {
        if let filteredRecords = trackerRecords?.filter({ $0.id == trackerId }) {
            return filteredRecords.count
        } else {
            return 0
        }
    }
    
    func isTrackerCompleted(trackerId: UUID, date: Date) -> Bool {
        let request = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
        request.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                        #keyPath(TrackerRecordCoreData.trackerid),
                                        trackerId.uuidString,
                                        #keyPath(TrackerRecordCoreData.date),
                                        date as CVarArg)
        guard let trackerRecords = try? context.fetch(request) else {
            assertionFailure("Failed to fetch(request)")
            return false
        }
        return !trackerRecords.isEmpty
    }
}

extension TrackerRecordCoreData {
    func populate(from trackerRecord: TrackerRecord) {
        trackerid = trackerRecord.id
        date = trackerRecord.date
    }
}
