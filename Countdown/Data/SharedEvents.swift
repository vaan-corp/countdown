//
//  SharedEvents.swift
//  Countdown
//
//  Created by Asif on 16/02/23.
//

import Foundation
import EventKit

struct Events{
  // upcoming events
  var firstSevenUpcomingEvents: [EKEvent] { Preferences.shared.firstSevenUpcomingEvents}
  var nextFiveUpcomingEvents : [EKEvent] { Array(firstSevenUpcomingEvents.suffix(5))}
  var firstTwoUpcomingEvents : [EKEvent] { Array(firstSevenUpcomingEvents.prefix(2))}
  var nextUpcomingEventsCount: Int { Preferences.shared.upcomingEventsCount - firstTwoUpcomingEvents.count}
  
  // favorite events
  var firstSevenFavoriteEvents: [EKEvent] { Preferences.shared.firstSevenFavoriteEvents }
  var firstTwoFavoriteEvents : [EKEvent] { Array(firstSevenFavoriteEvents.prefix(2))}
  var nextFiveFavoriteEvents : [EKEvent] { Array(firstSevenFavoriteEvents.suffix(5))}
  var nextFavoriteEventsCount: Int { Preferences.shared.favoriteEventsCount - firstTwoFavoriteEvents.count}
}
