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
        guard
            let objects = self.fetchedResultController.fetchedObjects,
            let categories = try? objects.map({ try self.makeCategories(from: $0) })
        else { return [] }
        return categories
    }
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext
    private let trackerStore = TrackerStore()
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<TrackerCategoryUpdate.Move>?
    
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
    
    private func fetchedCategory(with title: String) throws -> TrackerCategoryCoreData? {
        let request = fetchedResultController.fetchRequest
        request.predicate = NSPredicate(format: "%K == %@", argumentArray: ["titleCategory", title])
        do {
            let category = try context.fetch(request)
            return category.first
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

