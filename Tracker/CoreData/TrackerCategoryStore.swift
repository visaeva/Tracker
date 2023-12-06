//
//  TrackerCategoryStore.swift
//  Tracker
//
//  Created by Victoria Isaeva on 07.10.2023.
//

import UIKit
import CoreData

// MARK: - Error
enum TrackerCategoryStoreError: Error {
    case errorTitle
    case errorCategory
    case errorCategoryModel
}

private struct TrackerCategoryUpdate {
    struct Move: Hashable {
        let oldIndex: Int
        let newIndex: Int
    }
    let insertedIndexes: IndexSet
    let deletedIndexes: IndexSet
    let updatedIndexes: IndexSet
    let movedIndexes: Set<Move>
}

protocol TrackerCategoryStoreDelegate {
    func update()
}

class TrackerCategoryStore: NSObject {
    
    // MARK: Public properties
    static let shared = TrackerCategoryStore()
    
    
    /*  var categories: [TrackerCategory] {
     guard let objects = self.fetchedResultController.fetchedObjects,
     var categories = try? objects.map({ try self.makeCategories(from: $0) })
     else { return [] }
     return categories
     }*/
    
    var categories: [TrackerCategory] {
        guard let objects = self.fetchedResultController.fetchedObjects,
              var categories = try? objects.map({ try self.makeCategories(from: $0) })
        else { return [] }
        return categories
    }
    
    var pinnedCategoryArray: [TrackerCategory] {
        let pinnedTrackers = TrackerStore.shared.pinnedTrackers
        let pinnedCategory = TrackerCategory(title: "Закрепленные", trackers: pinnedTrackers)
        return [pinnedCategory]
    }
    
    var previousCategoryTitle: String? {
        get {
            return UserDefaults.standard.string(forKey: previousCategoryKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: previousCategoryKey)
        }
    }
    
    // MARK: - Private Properties
    private let previousCategoryKey = "PreviousCategoryKey"
    private let context: NSManagedObjectContext
    private let trackerStore = TrackerStore()
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<TrackerCategoryUpdate.Move>?
    private let uiColorMarshalling = UIColorMarshalling()
    
    private lazy var fetchedResultController: NSFetchedResultsController<TrackerCategoryCoreData>! = {
        let request = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        let sortDescriptor = NSSortDescriptor(keyPath: \TrackerCategoryCoreData.titleCategory, ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        controller.delegate = self
        try? controller.performFetch()
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
    
    // MARK: Public Methods
    func createTrackerWithCategory(tracker: Tracker, with titleCategory: String) throws {
        if let currentCategory = try? fetchedCategory(with: titleCategory) {
            let trackerCoreData = try trackerStore.createTracker(from: tracker)
            currentCategory.addToTrackers(trackerCoreData)
        } else {
            let newCategory = TrackerCategoryCoreData(context: context)
            newCategory.titleCategory = titleCategory
            let trackerCoreData = try trackerStore.createTracker(from: tracker)
            newCategory.addToTrackers(trackerCoreData)
        }
        do {
            try context.save()
        } catch {
            throw TrackerCategoryStoreError.errorCategoryModel
        }
    }
    
    func createCategory(_ category: TrackerCategory) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: "TrackerCategoryCoreData", in: context) else { return }
        let categoryEntity = TrackerCategoryCoreData(entity: entity, insertInto: context)
        
        categoryEntity.titleCategory = category.title
        categoryEntity.trackers = NSSet(array: [])
        
        try context.save()
        try fetchedResultController.performFetch()
    }
    
    private func findTracker(with id: UUID) throws -> TrackerCoreData? {
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        request.predicate = NSPredicate(format: "%K == %@", argumentArray: ["trackerID", id as CVarArg])
        return try context.fetch(request).first
    }
    
    func editTrackerWithCategory(tracker: Tracker, oldCategoryTitle: String?, newCategoryTitle: String?) throws {
        do {
            guard let existingTracker = try findTracker(with: tracker.id) else {
                return
            }
            if let newCategoryTitle = newCategoryTitle {
                if let oldCategoryTitle = oldCategoryTitle, oldCategoryTitle != newCategoryTitle {
                    if let oldCategory = try fetchedCategory(with: oldCategoryTitle) {
                        oldCategory.removeFromTrackers(existingTracker)
                    }
                }
                let newCategory: TrackerCategoryCoreData
                if let fetchedNewCategory = try fetchedCategory(with: newCategoryTitle) {
                    newCategory = fetchedNewCategory
                } else {
                    newCategory = TrackerCategoryCoreData(context: context)
                    newCategory.titleCategory = newCategoryTitle
                }
                existingTracker.category = newCategory
            }
            
            existingTracker.name = tracker.name
            existingTracker.color = uiColorMarshalling.hexString(from: tracker.color)
            existingTracker.emoji = tracker.emoji
            existingTracker.mySchedule = tracker.mySchedule.map { $0.rawValue }.map(String.init).joined(separator: ",")
            
            try context.save()
            print("Tracker updated successfully")
        } catch {
            print("Ошибка при обновлении трекера: \(error)")
            throw TrackerCategoryStoreError.errorCategoryModel
        }
    }
    
    
    
    // MARK: Private Methods
    private func makeCategories(from trackerCategoryCoreData: TrackerCategoryCoreData) throws -> TrackerCategory {
        guard let title = trackerCategoryCoreData.titleCategory else {
            throw TrackerCategoryStoreError.errorTitle
        }
        
        guard let trackers = trackerCategoryCoreData.trackers else {
            throw TrackerCategoryStoreError.errorCategory
        }
        
        return TrackerCategory(title: title, trackers: trackers.compactMap { coreDataTracker -> Tracker? in
            if let coreDataTracker = coreDataTracker as? TrackerCoreData {
                return try? trackerStore.makeTracker(from: coreDataTracker)
            }
            return nil
        })
    }
    
    func fetchedCategory(with title: String) throws -> TrackerCategoryCoreData? {
        let request = fetchedResultController.fetchRequest
        request.predicate = NSPredicate(format: "%K == %@", argumentArray: ["titleCategory", title])
        do {
            let category = try context.fetch(request)
            return category.first
        } catch {
            throw TrackerCategoryStoreError.errorCategoryModel
        }
    }
    
    func pinTracker(_ tracker: Tracker, oldCategoryTitle: String?) throws {
        do {
            guard let existingTracker = try findTracker(with: tracker.id) else {
                return
            }
            if let oldCategoryTitle = oldCategoryTitle {
                if let oldCategory = try fetchedCategory(with: oldCategoryTitle) {
                    oldCategory.removeFromTrackers(existingTracker)
                }
            }
            
            let pinnedCategoryTitle = "Закрепленные"
            let pinnedCategory: TrackerCategoryCoreData
            if let fetchedPinnedCategory = try fetchedCategory(with: pinnedCategoryTitle) {
                pinnedCategory = fetchedPinnedCategory
            } else {
                pinnedCategory = TrackerCategoryCoreData(context: context)
                pinnedCategory.titleCategory = pinnedCategoryTitle
            }
            
            existingTracker.category = pinnedCategory
            
            try context.save()
        } catch {
            throw TrackerCategoryStoreError.errorCategoryModel
        }
    }
    
    func unpinTracker(_ tracker: Tracker, oldCategoryTitle: String?) throws {
        do {
            guard let existingTracker = try findTracker(with: tracker.id) else {
                return
            }
            if let oldCategoryTitle = oldCategoryTitle {
                try addTrackerToCategory(existingTracker, categoryTitle: oldCategoryTitle)
                previousCategoryTitle = oldCategoryTitle
            }
            existingTracker.category = nil
            try context.save()
        } catch {
            throw TrackerCategoryStoreError.errorCategoryModel
        }
    }
    
    
    func addTrackerToCategory(_ tracker: TrackerCoreData, categoryTitle: String) throws {
        do {
            guard let category = try fetchedCategory(with: categoryTitle) else {
                return
            }
            
            category.addToTrackers(tracker)
            try context.save()
        } catch {
            throw TrackerCategoryStoreError.errorCategoryModel
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            let error = error as NSError
            assertionFailure(error.localizedDescription)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { fatalError() }
            insertedIndexes?.insert(indexPath.item)
        case .delete:
            guard let indexPath = indexPath else { fatalError() }
            deletedIndexes?.insert(indexPath.item)
        case .update:
            guard let indexPath = indexPath else { fatalError() }
            updatedIndexes?.insert(indexPath.item)
        case .move:
            guard let oldIndexPath = indexPath, let newIndexPath = newIndexPath else { fatalError() }
            movedIndexes?.insert(.init(oldIndex: oldIndexPath.item, newIndex: newIndexPath.item))
        @unknown default: return
        }
    }
}

extension TrackerCategoryStore {
    func getCategoryTitleByTrackerID(_ trackerID: UUID) -> String? {
        guard let objects = self.fetchedResultController.fetchedObjects else {
            return nil
        }
        for object in objects {
            if let coreDataTrackerCategory = object as? TrackerCategoryCoreData,
               let trackers = coreDataTrackerCategory.trackers as? Set<TrackerCoreData>,
               let coreDataTracker = trackers.first(where: { $0.trackerID == trackerID }),
               let category = try? makeCategories(from: coreDataTrackerCategory) {
                
                return category.title
            }
        }
        
        return nil
    }
}
