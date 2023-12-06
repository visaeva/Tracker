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
    
    var categories: [TrackerCategory] {
        guard let objects = self.fetchedResultController.fetchedObjects,
              var categories = try? objects.map({ try self.makeCategories(from: $0) })
        else { return [] }

        categories.removeAll { $0.title == "Закрепленные" }

        return categories
    }

    

    
    // MARK: - Private Properties
    
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
        self.createPinCategory()
    }
    
    // MARK: Public Methods
    func createTrackerWithCategory(tracker: Tracker, with titleCategory: String) throws {
        // if let currentCategory = try? fetchedCategory(with: titleCategory) {
        if let currentCategory = fetchedCategory(with: titleCategory) {
            trackerStore.createTracker(from: tracker, category: currentCategory)
            print(#function, currentCategory)
            // currentCategory.addToTrackers(trackerCoreData)
        } else {
            let newCategory = TrackerCategoryCoreData(context: context)
            newCategory.titleCategory = titleCategory
            trackerStore.createTracker(from: tracker, category: newCategory)
            print(#function, newCategory)
            // newCategory.addToTrackers(trackerCoreData)
        }
        do {
            try context.save()
        } catch {
            throw TrackerCategoryStoreError.errorCategoryModel
        }
    }
    
    
    func createPinCategory() {
      let name = "Закрепленные"
      if let fetchedNewCategory = fetchedCategory(with: name) {
        print(#function, "Закрепленные is already here")
      } else {
        guard let entity = NSEntityDescription.entity(forEntityName: "TrackerCategoryCoreData", in: context) else { return }
        let categoryEntity = TrackerCategoryCoreData(entity: entity, insertInto: context)

        categoryEntity.titleCategory = name
         
        categoryEntity.trackers = NSSet(array: [])
        saveContext()
        print(#function, entity)
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
    
    func fetchedCategory(with title: String) -> TrackerCategoryCoreData? {
    // func fetchedCategory(with title: String) throws -> TrackerCategoryCoreData? {
       let request = fetchedResultController.fetchRequest
       request.predicate = NSPredicate(format: "%K == %@", argumentArray: ["titleCategory", title])
      guard let category = try? context.fetch(request) else { return nil }
      return category.first
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
