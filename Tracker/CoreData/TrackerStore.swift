//
//  TrackerStore.swift
//  Tracker
//
//  Created by Victoria Isaeva on 07.10.2023.
//

import UIKit
import CoreData

// MARK: - Error
enum TrackerStoreError: Error {
    case error
}

protocol TrackerStoreDelegate {
    func trackerStoreDelegate()
}

final class TrackerStore: NSObject {
    // MARK: Public properties
    var delegate: TrackerStoreDelegate?
    var insertedIndexes: IndexSet?
    var deletedIndexes: IndexSet?
    
    var trackers: [Tracker] {
        guard let objects = fetchedResultController.fetchedObjects,
              let trackers = try? objects.map({
                  try makeTracker(from: $0)
              })
        else { return [] }
        return trackers
    }
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext
    private let uiColorMarshalling = UIColorMarshalling()
    
    private lazy var fetchedResultController: NSFetchedResultsController<TrackerCoreData> = {
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        let sortDescriptor = NSSortDescriptor(keyPath: \TrackerCoreData.name, ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        try? frc.performFetch()
        frc.delegate = self
        return frc
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
    
    // MARK: Public Methods
    func createTracker(from tracker: Tracker) throws -> TrackerCoreData {
        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.trackerID = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.color = uiColorMarshalling.hexString(from: tracker.color)
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.mySchedule = tracker.mySchedule.map { $0.rawValue }.map(String.init).joined(separator: ",")
        trackerCoreData.records = []
        saveContext()
        return trackerCoreData
    }
    
    func updateTrackerCoreData(value: TrackerRecord) {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(TrackerCoreData.trackerID), "\(value.id)")
        
        guard let trackers = try? context.fetch(request) else {
            assertionFailure("Enabled to fetch(request)")
            return
        }
        if let tracker = trackers.first {
            let trackerRecording = TrackerRecordCoreData(context: context)
            trackerRecording.trackerid = value.id
            trackerRecording.date = value.date
            tracker.addToRecords(trackerRecording)
            saveContext()
        }
    }
    
    func makeTracker(from trackersCoreData: TrackerCoreData) throws -> Tracker {
        guard let id = trackersCoreData.trackerID,
              let name = trackersCoreData.name,
              let color = trackersCoreData.color,
              let emoji = trackersCoreData.emoji,
              let myScheduleString = trackersCoreData.mySchedule,
              let records = trackersCoreData.records
        else {
            print("Failed to retrieve necessary data from CoreData")
            throw TrackerStoreError.error }
        
        let mySchedule = myScheduleString.split(separator: ",").compactMap { Int($0) }.compactMap { WeekDay(rawValue: $0) }
        
        return Tracker(id: id,
                       name: name,
                       color: uiColorMarshalling.color(from: color),
                       emoji: emoji,
                       mySchedule: Set(mySchedule),
                       records: [])
    }
    
    func deleteTracker(with id: UUID) {
        print("Deleting Tracker with id: \(id)")
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(TrackerCoreData.trackerID), id.uuidString)
        guard let trackers = try? context.fetch(request) else {
            assertionFailure("Enabled to fetch(request)")
            return
        }
        if let trackerDelete = trackers.first {
            context.delete(trackerDelete)
            saveContext()
        }
    }
    
    func deleteAllTrackers() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TrackerCoreData")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            let error = error as NSError
        }
    }
    
    // MARK: Private Methods
    private func saveContext() {
        do {
            try context.save()
        } catch {
            let error = error as NSError
            assertionFailure("Failed to save context: \(error.localizedDescription)")
        }
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerStoreDelegate()
        insertedIndexes = nil
        deletedIndexes = nil
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?)
    { switch type {
    case .delete where indexPath != nil:
        deletedIndexes?.insert(indexPath!.item)
    case .insert where newIndexPath != nil:
        insertedIndexes?.insert(newIndexPath!.item)
    default:
        break
    }
    }
}
