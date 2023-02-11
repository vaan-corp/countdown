//
//  FavoriteEvent.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import MIDataStore
import CoreData
import EventKit
import SwiftUI

public class FavoriteModel: ObservableObject {
  let event: EKEvent
  
  @Published public var image: Image
  
  public init(event: EKEvent) {
    self.event = event
    
    if CDStore.shared.isFavorite(event) {
      image = Image(systemName: "heart.fill")
    } else {
      image = Image(systemName: "heart")
    }
  }
  
  public func toggle() {
    if isFavEvent {
      CDStore.shared.deleteEvent(withID: self.event.eventIdentifier)
      self.image = Image(systemName: "heart")
    } else {
      CDStore.shared.favorite(self.event)
      self.image = Image(systemName: "heart.fill")
    }
  }
  
  public var isFavEvent: Bool { CDStore.shared.isFavorite(event) }
}

public class CDStore: BaseStore {
  
  static let shared: CDStore = .init(modelName: FavEvent.entityName)
  
  var entityName: String { FavEvent.entityName }
  var appGroup: String = "group.com.skydevz.Countdown"
  
  public func prepare(forAppGroup groupName: String) {
    CDStore.shared.appGroup = groupName
  }
  
  public func isFavorite(_ event: EKEvent) -> Bool {
    let fetchRequest = fetchRequestForEvent(withID: event.eventIdentifier)
    
    guard let objects = try? mainContext.fetch(fetchRequest) else {
      return false
    }
    
    return !objects.isEmpty
  }
  
  public var allFavIdentifiers: [String] {
    guard let objects = try? mainContext.fetch(FavEvent.fetchRequest) as? [NSManagedObject] else {
      return []
    }
    
    return objects.compactMap({ $0.value(forKey: FavEvent.id) as? String })
  }
  
  //    public var allFavorites: [FavoriteEvent] {
  //        guard let objects = try? mainContext?.fetch(FavEvent.fetchRequest) as? [NSManagedObject] else {
  //                return []
  //        }
  //
  //        return objects.compactMap({ $0.value(forKey: FavEvent.id) as? String })
  //    }
  
  public func favorite(_ event: EKEvent) {
    let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: mainContext)
    
    //        if let favEvent = object as? FavoriteEvent {
    //            favEvent.eventID = event.eventIdentifier
    //            favEvent.occurenceDate = event.occurrenceDate
    //        } else {
    object.setValue(event.eventIdentifier, forKey: FavEvent.id)
    object.setValue(event.occurrenceDate, forKey: FavEvent.date)
    //        }
    
    "event saved with id - \(event.eventIdentifier ?? "")".log()
    
    mainContext.update()
  }
  
  public func deleteEvent(withID string: String) {
    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequestForEvent(withID: string))
    
    do {
      try mainContext.execute(batchDeleteRequest)
      "deleted event with id - \(string)".log()
    } catch {
      "Unable to delete entity with name \(entityName)".log()
    }
    
    // Core data save not required after performing delete batch request
    // as it acts directly on the underlying SQLite store
    //        MICoreData.update()
  }
  
  func fetchRequestForEvent(withID string: String) -> NSFetchRequest<NSFetchRequestResult>{
    let fetchRequest = FavEvent.fetchRequest
    fetchRequest.predicate = NSPredicate(format: "\(FavEvent.id) = %@", string)
    return fetchRequest
  }
  
  public override func makeContainer() -> NSPersistentContainer {
    SharedContainer(name: "Countdown", managedObjectModel: objectModel)
  }
  
  var objectModel: NSManagedObjectModel {
    let model: NSManagedObjectModel = NSManagedObjectModel()
    model.entities = [favoriteEntity]
    return model
  }
  
  var favoriteEntity: NSEntityDescription {
    let entity = NSEntityDescription()
    entity.name = entityName
    entity.addAttribute(name: FavEvent.id, type: .stringAttributeType, isUnique: true)
    entity.addAttribute(name: FavEvent.date, type: .dateAttributeType)
    return entity
  }
}

class SharedContainer: NSPersistentCloudKitContainer {
  override open class func defaultDirectoryURL() -> URL {
    let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CDStore.shared.appGroup)
    return storeURL ?? super.defaultDirectoryURL()
  }
}

struct FavEvent {
  static var fetchRequest: NSFetchRequest<NSFetchRequestResult> {
    NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
  }
  
  static var entityName: String { "FavoriteEvent" }
  static var id: String { "eventID" }
  static var date: String { "occurenceDate" }
}

//@objc(FavoriteEvent) public class FavoriteEvent: NSManagedObject {
////    @nonobjc public class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
////        return NSFetchRequest<NSFetchRequestResult>(entityName: CDStore.entityName)
////    }
//
//    @NSManaged public var eventID: String
//    @NSManaged public var occurenceDate: Date
//}
