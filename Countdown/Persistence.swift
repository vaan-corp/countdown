//
//  Persistence.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import CoreData
import EventKit

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSCustomPersistentContainer(name: Preferences.appName)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension PersistenceController {
  func saveEnabledCallID(_ id: String) {
    let newItem = EnabledCalendar(context: container.viewContext)
    newItem.identifier = id
    
    do {
      try container.viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
  }
  
  func isEnabledCallID(_ id: String) -> Bool {
    let fetchRequest = fetchRequestForEnabledCallID(withID: id)
    guard let objects = try? container.viewContext.fetch(fetchRequest) else {
      return false
    }
    return !objects.isEmpty
  }
  
  func removeEnabledCallID(withID id: String) {
    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequestForEnabledCallID(withID: id))
    
    do {
      try container.viewContext.execute(batchDeleteRequest)
      "deleted calendar with id - \(id)".log()
    } catch {
      "Unable to delete entity with name EnabledCallID".log()
    }
  }
  
  func fetchRequestForEnabledCallID(withID string: String) -> NSFetchRequest<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EnabledCalendar")
    fetchRequest.predicate = NSPredicate(format: "identifier = %@", string)
    return fetchRequest
  }
  
  func fetchEnabledCalendars() -> [String] {
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "EnabledCalendar")
    guard let objects = try? container.viewContext.fetch(fetchRequest) as? [EnabledCalendar] else { return [] }
    return objects.compactMap { $0.identifier }
  }
  
  // favorite events
  func isFavorite(_ event: EKEvent) -> Bool {
    let fetchRequest = fetchRequestForEvent(withID: event.eventIdentifier)
    
    guard let objects = try? container.viewContext.fetch(fetchRequest) else {
      return false
    }
    
    return !objects.isEmpty
  }
  
  func favorite(_ event: EKEvent) {
    let newItem = FavoriteEvent(context: container.viewContext)
    newItem.eventID = event.eventIdentifier
    newItem.occurenceDate = event.occurrenceDate
    
    do {
      try container.viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
  }
  
  func deleteEvent(withID id: String) {
    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequestForEvent(withID: id))
    
    do {
      try container.viewContext.execute(batchDeleteRequest)
      "deleted event with id - \(id)".log()
    } catch {
      "Unable to delete entity with name FavoriteEvent".log()
    }
  }
  
  func fetchRequestForEvent(withID string: String) -> NSFetchRequest<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavoriteEvent")
    fetchRequest.predicate = NSPredicate(format: "eventID = %@", string)
    return fetchRequest
  }
}
