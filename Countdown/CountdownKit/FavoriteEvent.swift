//
//  FavoriteEvent.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import CoreData
import EventKit
import MIDataStore
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
      if Preferences.shared.showFavoritesOnly {
        withAnimation {
          Preferences.shared.displayEvents.removeAll(where: { $0.eventIdentifier == self.event.eventIdentifier })
        }
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
