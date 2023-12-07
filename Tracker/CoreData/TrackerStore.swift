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

protocol TrackerStoreDelegate: AnyObject {
    func didUpdate()
}

protocol TrackerViewControllerDataSource {
    func cellData(at indexPath: IndexPath) -> Tracker?
    func numberOfRows(at section: Int) -> Int
    func titleForTrackerSection(section: Int) -> String
}

final class TrackerStore: NSObject {
    
    // MARK: Public properties
    static let shared = TrackerStore()
    weak var delegate: TrackerStoreDelegate?
    var dataSource: TrackerViewControllerDataSource?
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
    
    var pinnedTrackers: [Tracker] {
        guard let objects = self.fetchedResultController.fetchedObjects else {
            return []
        }
        let pinnedTrackers = try? objects.compactMap { try self.makeTracker(from: $0) }.filter { $0.isPinned }
        return pinnedTrackers ?? []
    }
    
    var statisticViewModel: StatisticViewModel?
    // MARK: - Private Properties
    private var currentNameFilter: String?
    private var filterWeekDay: Int = 0
    private var selectedCategory: String?
    private let context: NSManagedObjectContext
    private let uiColorMarshalling = UIColorMarshalling()
    
    lazy var fetchedResultController: NSFetchedResultsController<TrackerCoreData> = {
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        
        let sortDescriptor = NSSortDescriptor(keyPath: \TrackerCoreData.category?.titleCategory, ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: #keyPath(TrackerCoreData.category.titleCategory),
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
    func updateCategoryPredicate(category: String?) {
        selectedCategory = category
        applyPredicate()
    }
    
    func updateNameFilter(nameFilter: String?) {
        currentNameFilter = nameFilter
        applyPredicate()
    }
    
    func updateDayOfWeekPredicate(for date: Date) {
        filterWeekDay = (Calendar.current.component(.weekday, from: date) + 5) % 7
        let dayPredicate = NSPredicate(format: "mySchedule CONTAINS[c] %@", "\(filterWeekDay)")
        fetchedResultController.fetchRequest.predicate = dayPredicate
        
        do {
            try fetchedResultController.performFetch()
        } catch {
            print("Error performing fetch: \(error)")
        }
    }
    
    func applyPredicate() {
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "mySchedule CONTAINS[c] %@", "\(filterWeekDay)"))
        if let category = selectedCategory {
            predicates.append(NSPredicate(format: "category.name == %@", category))
        }
        if let nameFilter = currentNameFilter, !nameFilter.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[c] %@", nameFilter))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchedResultController.fetchRequest.predicate = compoundPredicate
        do {
            try fetchedResultController.performFetch()
        } catch {
            print("Error performing fetch: \(error)")
        }
    }
    
    func createTracker(from tracker: Tracker, category: TrackerCategoryCoreData) {
        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.trackerID = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.color = uiColorMarshalling.hexString(from: tracker.color)
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.mySchedule = tracker.mySchedule.map { $0.rawValue }.map(String.init).joined(separator: ",")
        trackerCoreData.isPinned = tracker.isPinned
        trackerCoreData.category = category
        trackerCoreData.mainCategory = tracker.mainCategory
        trackerCoreData.records = []
        saveContext()
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
            notifyStatisticsModel()
        }
    }
    
    private func notifyStatisticsModel() {
        statisticViewModel?.viewWillAppear()
    }
    
    func setStatisticViewModel(_ viewModel: StatisticViewModel) {
        statisticViewModel = viewModel
    }
    
    func makeTracker(from trackersCoreData: TrackerCoreData) throws -> Tracker {
        guard let id = trackersCoreData.trackerID,
              let name = trackersCoreData.name,
              let color = trackersCoreData.color,
              let emoji = trackersCoreData.emoji,
              let myScheduleString = trackersCoreData.mySchedule,
              let mainCategory = trackersCoreData.mainCategory
        else {
            throw TrackerStoreError.error }
        
        let mySchedule = myScheduleString.split(separator: ",").compactMap { Int($0) }.compactMap { WeekDay(rawValue: $0) }
        let isPinned = trackersCoreData.isPinned
        
        return Tracker(id: id,
                       name: name,
                       color: uiColorMarshalling.color(from: color),
                       emoji: emoji,
                       mySchedule: Set(mySchedule),
                       records: [], isPinned: isPinned,
                       mainCategory: mainCategory
        )
    }
    
    func deleteTracker(with id: UUID) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackerCoreData")
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(TrackerCoreData.trackerID), id.uuidString)
        do {
            let results = try context.fetch(request)
            for object in results {
                if let trackerObject = object as? TrackerCoreData {
                    if let records = trackerObject.records {
                        for case let record as TrackerRecordCoreData in records {
                            context.delete(record)
                        }
                    }
                    context.delete(trackerObject)
                }
            }
            saveContext()
        } catch {
            print("Error fetching and deleting trackers: \(error)")
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
    
    func getTracker(with id: UUID) -> Tracker? {
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(TrackerCoreData.trackerID), id.uuidString)
        guard let trackerCoreData = try? context.fetch(request).first else {
            return nil
        }
        do {
            return try makeTracker(from: trackerCoreData)
        } catch {
            print("Error making Tracker from CoreData: \(error)")
            return nil
        }
    }
    
    func getTrackerCoreData(from tracker: Tracker) -> TrackerCoreData? {
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(TrackerCoreData.trackerID), tracker.id.uuidString)
        guard let trackerCoreData = try? context.fetch(request).first else {
            return nil
        }
        return trackerCoreData
    }
    
    func setIsPinned(for tracker: Tracker) {
        guard var trackerCoreData = getTrackerCoreData(from: tracker) else {
            return
        }
        trackerCoreData.isPinned.toggle()
        if trackerCoreData.isPinned {
            if let pinnedCategory = TrackerCategoryStore.shared.fetchedCategory(with: LocalizableStringKeys.pin) {
                pinnedCategory.addToTrackers(trackerCoreData)
            }
        } else {
            let mainCategoryTitle = tracker.mainCategory
            if !mainCategoryTitle.isEmpty,
               let mainCategory = TrackerCategoryStore.shared.fetchedCategory(with: mainCategoryTitle) {
                mainCategory.addToTrackers(trackerCoreData)
            }
        }
        saveContext()
        delegate?.didUpdate()
    }
    
    func getMainCategoryByTrackerID(_ trackerID: UUID) -> String? {
        guard let objects = self.fetchedResultController.fetchedObjects else {
            return nil
        }
        if let coreDataTracker = objects.first(where: { $0.trackerID == trackerID }) {
            return coreDataTracker.mainCategory
        }
        return nil
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

// MARK: NSFetchedResultsControllerDelegate
extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdate()
        insertedIndexes = nil
        deletedIndexes = nil
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ){
        switch type {
        case .delete where indexPath != nil:
            deletedIndexes?.insert(indexPath!.item)
        case .insert where newIndexPath != nil:
            insertedIndexes?.insert(newIndexPath!.item)
        default:
            break
        }
    }
}

// MARK: TrackerViewControllerDataSource
extension TrackerStore: TrackerViewControllerDataSource {
    func numberOfSections() -> Int {
        fetchedResultController.sections?.count ?? 0
    }
    
    func cellData(at indexPath: IndexPath) -> Tracker? {
        return try? makeTracker(from: fetchedResultController.object(at: indexPath))
    }
    
    func numberOfRows(at section: Int) -> Int {
        fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func titleForTrackerSection(section: Int) -> String {
        fetchedResultController.sections?[section].name ?? ""
    }
}


extension TrackerStore {
    func filterForToday() {
        let currentDate = Date().deleteTime()
        let datePredicate = NSPredicate(format: "ANY records.date == %@", currentDate! as NSDate)
        fetchedResultController.fetchRequest.predicate = datePredicate
        
        do {
            try fetchedResultController.performFetch()
        } catch {
            print("Error performing fetch: \(error)")
        }
    }
    
    func filterCompleted(for date: Date) {
        let completedPredicate = NSPredicate(format: "ANY records.date == %@", date as NSDate)
        fetchedResultController.fetchRequest.predicate = completedPredicate
        
        do {
            try fetchedResultController.performFetch()
        } catch {
            print("Error performing fetch: \(error)")
        }
    }
    
    func filterNotCompleted(for date: Date) {
        let currentFilterWeekDay = (Calendar.current.component(.weekday, from: date) + 5) % 7
        let notCompletedPredicate = NSPredicate(format: "SUBQUERY(records, $record, $record.date == %@).@count == 0 AND mySchedule CONTAINS[c] %@", date as NSDate, "\(currentFilterWeekDay)")
        fetchedResultController.fetchRequest.predicate = notCompletedPredicate
        
        do {
            try fetchedResultController.performFetch()
        } catch {
            print("Error performing fetch: \(error)")
        }
    }
    
    func clearFilters() {
        fetchedResultController.fetchRequest.predicate = nil
        do {
            try fetchedResultController.performFetch()
        } catch {
            print("Error performing fetch: \(error)")
        }
    }
}

