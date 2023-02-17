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
import WidgetKit

public class FavoriteModel: ObservableObject {
  let event: EKEvent
  
  @Published public var image: Image
  
  public init(event: EKEvent) {
    self.event = event
    
    if PersistenceController.shared.isFavorite(event) {
      image = Image(systemName: "heart.fill")
    } else {
      image = Image(systemName: "heart")
    }
  }
  
  public func toggle() {
    if isFavEvent {
      PersistenceController.shared.deleteEvent(withID: self.event.eventIdentifier)
      withAnimation {
        Preferences.shared.displayEvents.removeAll(where: { $0.eventIdentifier == self.event.eventIdentifier })
      }
      self.image = Image(systemName: "heart")
    } else {
      PersistenceController.shared.favorite(self.event)
      self.image = Image(systemName: "heart.fill")
    }
    WidgetCenter.shared.reloadTimelines(ofKind: "favEvents")
  }
  
  public var isFavEvent: Bool { PersistenceController.shared.isFavorite(event) }
}

extension PersistenceController {
  
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
      // Replace this implementation with code to handle the error appropriately.
      // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
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
  
  func fetchRequestForEvent(withID string: String) -> NSFetchRequest<NSFetchRequestResult>{
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavoriteEvent")
    fetchRequest.predicate = NSPredicate(format: "eventID = %@", string)
    return fetchRequest
  }
  
}

