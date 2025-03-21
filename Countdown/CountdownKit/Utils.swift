//
//  Utils.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import CoreData
import EventKit
import SwiftUI

public class Preferences: ObservableObject {
  private init() {
    displayEvents = events
  }
  
  static public let shared = Preferences()
  
  @Published public var searchText: String = ""
  
  @Published public var showFavoritesOnly: Bool = false

  public var events: [EKEvent] {
    EventStore.getEvents(inCalendars: enabledCalendars)
  }
  
  @Published public var displayEvents = [EKEvent]()
  
  public var favoriteEvents: [EKEvent] {
    events.filter { PersistenceController.shared.isFavorite($0) }
  }
  
  public var enabledCalIDs: [String] { PersistenceController.shared.fetchEnabledCalendars() }
  
  public var firstSevenUpcomingEvents: [EKEvent] {Array(events.prefix(7)) }
   
  public var firstSevenFavoriteEvents: [EKEvent] {Array(favoriteEvents.prefix(7)) }
  
  public var upcomingEventsCount: Int {events.count }
  
  public var favoriteEventsCount: Int {favoriteEvents.count }
  
  static public let appGroup: String = "group.imthath.countdown"
  
  static public let appName: String = "Countdown"
  
  @Published public var endDate = CDDefault.endDate {
    didSet { CDDefault.endDate = endDate }
  }
  
  @Published public var displayComponent = CDDefault.displayComponent {
    didSet { CDDefault.displayComponent = displayComponent }
  }
  
  @Published public var showEventAsCard = CDDefault.showEventAsCard {
    didSet { CDDefault.showEventAsCard = showEventAsCard }
  }
  
  @Published public var showHeartInList = CDDefault.showHeartInList {
    didSet { CDDefault.showHeartInList = showHeartInList }
  }
  
  @Published public var isPaidUser = CDDefault.isPaidUser {
    didSet { CDDefault.isPaidUser = isPaidUser }
  }
  
  @Published public var accessDenied: Bool = {
    let access = EKEventStore.authorizationStatus(for: .event)
    return access == .denied || access == .restricted
  }()
  
  public var enabledCalendars: [EKCalendar] {
    EventStore.calendars
      .filter({ enabledCalIDs.contains($0.calendarIdentifier) })
  }
  
  public var calendarComponent: Calendar.Component {
    CDDefault.components[displayComponent]
  }
  
  @Published public var allCalendars: [CDCalendar] = Preferences.getAllCalendars()
  
  public func handlePremiumFeatures() {
    if !isPaidUser {
      showHeartInList = false
    }
  }
  
  static public func getAllCalendars() -> [CDCalendar] {
    EventStore.calendars.map {
      CDCalendar(calendar: $0,
                 isEnabled: CDDefault.enabledCalIDs.contains($0.calendarIdentifier))
    }
  }
  
  public func updateAllCalendars() {
    allCalendars = Preferences.getAllCalendars()
  }
  
  public var enabledCalendarsDisplayString: String {
    if enabledCalIDs.isEmpty {
      return "No calendar"
    } else if enabledCalIDs.count == 1 {
      return enabledCalendars.first?.title ?? "1 Calendar"
    }
    
    return "\(enabledCalIDs.count) Calendars"
  }
  
  public func updateEvents() {
    updateSearchResults()
  }
  
  public func updateSearchResults() {
    guard !searchText.isEmpty else {
      displayEvents = events
      return
    }
    
    displayEvents = events.filter {
      $0.title
        .localizedCaseInsensitiveContains(
          searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
  }
}

public struct CDDefault {
  static public var components: [Calendar.Component] {
    [.day, .weekOfYear, .month]
  }
  
  @CustomDefault("endDate", defaultValue: Self.defaultEndDate)
  static public var endDate: Date
  
  @CustomDefault("installedDate", defaultValue: Date())
  static public var installedDate: Date
  
  @CustomDefault("displayComponent", defaultValue: 0)
  static public var displayComponent: Int
  
  @CustomDefault("enabledCalendars", defaultValue: [])
  static public var enabledCalIDs: [String]
  
  @CustomDefault("isFirstLaunch", defaultValue: true)
  static public var isFirstLaunch: Bool
  
  @CustomDefault("showEventAsCard", defaultValue: true)
  static public var showEventAsCard: Bool
  
  @CustomDefault("showHeartInList", defaultValue: true)
  static public var showHeartInList: Bool

  @CustomDefault("isPaidUser", defaultValue: false)
  static public var isPaidUser: Bool
  
  @CustomDefault("hasSubscriptionEnded", defaultValue: false)
  static public var hasSubscriptionEnded: Bool
  
  @CustomDefault("isMigratedFromStandardDefaults", defaultValue: false)
  static public var isMigratedFromStandardDefaults: Bool
  
  static public var enabledCalendars: [EKCalendar] {
    EventStore.calendars.filter({ enabledCalIDs.contains($0.calendarIdentifier) })
  }
  
  static public var defaultEndDate: Date {
    Calendar.current.date(byAdding: .year, value: 1, to: Date()) ??  Date(timeIntervalSinceNow: 31556952 * 1)
  }
  
  public static func migrate() {
    if Default.isFirstLaunch || isMigratedFromStandardDefaults { return }
    
    endDate = Default.endDate
    displayComponent = Default.displayComponent
    enabledCalIDs = Default.enabledCalendars
    isFirstLaunch = Default.isFirstLaunch
    showEventAsCard = Default.showEventAsCard
    isMigratedFromStandardDefaults = true
  }
}

struct Default {
  internal static var custom = UserDefaults(suiteName: Preferences.appGroup)
  
  static public var components: [Calendar.Component] {
    [.day, .weekOfYear, .month]
  }
  
  @StandardDefault("endDate", defaultValue: Self.defaultEndDate)
  static public var endDate: Date
  
  @StandardDefault("installedDate", defaultValue: Date())
  static public var installedDate: Date
  
  @StandardDefault("displayComponent", defaultValue: 0)
  static public var displayComponent: Int
  
  @StandardDefault("enabledCalendars", defaultValue: [])
  static public var enabledCalendars: [String]
  
  @StandardDefault("isFirstLaunch", defaultValue: true)
  static public var isFirstLaunch: Bool
  
  @StandardDefault("showEventAsCard", defaultValue: true)
  static public var showEventAsCard: Bool
  
  static public var defaultEndDate: Date {
    Calendar.current.date(byAdding: .year, value: 1, to: Date()) ??  Date(timeIntervalSinceNow: 31556952 * 1)
  }
}

public class EventStore {
  static public var store = EKEventStore()
  
  static public func updateCalendars() {
    Preferences.shared.updateAllCalendars()
  }
  
  static public func getCalendars() -> [EKCalendar] {
    let calendars = store
      .calendars(for: .event)
      .sorted(by: { $0.type.rawValue < $1.type.rawValue })
    
    if CDDefault.isFirstLaunch {
      CDDefault.enabledCalIDs = calendars.map { $0.calendarIdentifier }
      CDDefault.installedDate = Date()
      CDDefault.isFirstLaunch = false
    }
    
    return calendars
  }
  
  static public func save() {
    try? store.commit()
  }
  
  static public var calendars: [EKCalendar] { getCalendars() }
  
  static public func getEvents(inCalendars calendars: [EKCalendar]) -> [EKEvent] {
    guard !calendars.isEmpty else { return [] }
    
    let predicate = store.predicateForEvents(withStart: Date(),
                                             end: CDDefault.endDate,
                                             calendars: calendars)
        
    return store
      .events(matching: predicate)
      .distinct
      .sorted(by: { $0.occurrenceDate < $1.occurrenceDate })
  }
}

public struct TimeGap {
  public var days: Int64 = 0
  public var hours: Int = 0
  public var minutes: Int = 0
  public var seconds: Int = 0
  
  public init() { }
}

@propertyWrapper
public struct CustomDefault<T> {
  let key: String
  let defaultValue: T
  
  init(_ key: String, defaultValue: T) {
    self.key = key
    self.defaultValue = defaultValue
  }
  
  public var wrappedValue: T {
    get { Default.custom?.object(forKey: key) as? T ?? defaultValue }
    set { Default.custom?.set(newValue, forKey: key) }
  }
}

@propertyWrapper
public struct StandardDefault<T> {
  public let key: String
  public let defaultValue: T
  
  public init(_ key: String, defaultValue: T) {
    self.key = key
    self.defaultValue = defaultValue
  }
  
  public var wrappedValue: T {
    get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
    set { UserDefaults.standard.set(newValue, forKey: key) }
  }
}

public class CDCalendar: ObservableObject {
  @Published public var isEnabled: Bool
  
  public var name: String
  public var id: String
  public var color: Color
  
  public init(calendar: EKCalendar, isEnabled: Bool = false) {
    self.id = calendar.calendarIdentifier
    self.name = calendar.title
    self.isEnabled = isEnabled
    self.color = calendar.color
  }
}
