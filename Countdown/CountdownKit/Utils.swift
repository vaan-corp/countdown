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
    events = EventStore.getEvents(inCalendars: selectedCalendars)
    searchResults = events
    displayEvents = events
  }
  
  static public let shared = Preferences()
  
  //    public static var layoutDirection: LayoutDirection = .leftToRight
  
  @Published public var searchText: String = ""
  
  @Published public var events = [EKEvent]()
  
  @Published public var searchResults = [EKEvent]()
  
  @Published public var displayEvents = [EKEvent]()
  
  //    @Published public var favoriteEvents = [EKEvent]()
  
  public var favoriteEvents: [EKEvent] {
    events.filter { PersistenceController.shared.isFavorite($0) }
  }
  
  public var firstSevenUpcomingEvents: [EKEvent] {Array(events.prefix(7)) }
   
  public var firstSevenFavoriteEvents: [EKEvent] {Array(favoriteEvents.prefix(7)) }
  
  public var upcomingEventsCount: Int {events.count }
  
  public var favoriteEventsCount: Int {favoriteEvents.count }
  
  //TODO: change the app group to old one later ("group.com.skydevz.countdown")
  static public let appGroup: String = "group.com.skydevz.CountDown"
  
  static public let appName: String = "Countdown"
  
  @Published public var endDate = CDDefault.endDate {
    didSet { CDDefault.endDate = endDate }
  }
  
  @Published public var displayComponent = CDDefault.displayComponent {
    didSet { CDDefault.displayComponent = displayComponent }
  }
  
  @Published public var selectedCalIDs = CDDefault.selectedCalIDs {
    didSet { CDDefault.selectedCalIDs = selectedCalIDs }
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
  
  //    @Published public var confirmOnDelete = CDDefault.confirmOnDelete {
  //        didSet { CDDefault.confirmOnDelete = confirmOnDelete }
  //    }
  
  @Published public var accessDenied: Bool = {
    let access = EKEventStore.authorizationStatus(for: .event)
    return access == .denied || access == .restricted
  }()
  
  public var selectedCalendars: [EKCalendar] {
    EventStore.calendars
      .filter({ selectedCalIDs.contains($0.calendarIdentifier) })
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
                 isSelected: CDDefault.selectedCalIDs.contains($0.calendarIdentifier))
    }
  }
  
  public func updateAllCalendars() {
    allCalendars = Preferences.getAllCalendars()
    if selectedCalIDs.isEmpty,
       let defaultID = EventStore.store.defaultCalendarForNewEvents?.calendarIdentifier {
      selectedCalIDs = [defaultID]
    }
  }
  
  public var selectedCalendarsDisplayString: String {
    if selectedCalIDs.isEmpty {
      return "No calendar"
    } else if selectedCalIDs.count == 1 {
      return selectedCalendars.first?.title ?? "1 Calendar"
    }
    
    return "\(selectedCalIDs.count) Calendars"
  }
  
  public func updateEvents() {
    events = EventStore.getEvents(inCalendars: selectedCalendars)
    updateSearchResults()
  }
  
  public func updateSearchResults() {
    guard !searchText.isEmpty else {
      searchResults = events
      return
    }
    
    searchResults = events.filter {
      $0.title
        .localizedCaseInsensitiveContains(
          searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
  }
  
  //    public func updateFavoriteEvents() {
  //        guard isPaidUser else {
  //            if !favoriteEvents.isEmpty {
  //                "Favorites set for user in free plan".log()
  //                favoriteEvents = []
  //            }
  //            return
  //        }
  //
  //        favoriteEvents = events.filter { CDStore.isFavorite($0) }
  //    }
}

public struct CDDefault {
  //    internal static var custom = UserDefaults(suiteName: "group.imthath.countdown")
  
  static public var components: [Calendar.Component] {
    [.day, .weekOfYear, .month]
  }
  
  @CustomDefault("endDate", defaultValue: Self.defaultEndDate)
  static public var endDate: Date
  
  @CustomDefault("installedDate", defaultValue: Date())
  static public var installedDate: Date
  
  @CustomDefault("displayComponent", defaultValue: 0)
  static public var displayComponent: Int
  
  @CustomDefault("selectedCalendars", defaultValue: [])
  static public var selectedCalIDs: [String]
  
  @CustomDefault("isFirstLaunch", defaultValue: true)
  static public var isFirstLaunch: Bool
  
  @CustomDefault("showEventAsCard", defaultValue: true)
  static public var showEventAsCard: Bool
  
  @CustomDefault("showHeartInList", defaultValue: true)
  static public var showHeartInList: Bool
  
//  @CustomDefault("isPaidUser", defaultValue: false)
//  static public var isPaidUser: Bool
  
  #if DEBUG
  @CustomDefault("isPaidUser", defaultValue: true)
  static public var isPaidUser: Bool
  #endif
  
  @CustomDefault("hasSubscriptionEnded", defaultValue: false)
  static public var hasSubscriptionEnded: Bool
  
  //    @CustomDefault("confirmOnDelete", defaultValue: true)
  //    static public var confirmOnDelete: Bool
  
  @CustomDefault("isMigratedFromStandardDefaults", defaultValue: false)
  static public var isMigratedFromStandardDefaults: Bool
  //    @CustomDefault("firstAccessGranted", defaultValue: true)
  //    static public var isFirstLaunch: Bool
  
  static public var selectedCalendars: [EKCalendar] {
    EventStore.calendars.filter({ selectedCalIDs.contains($0.calendarIdentifier) })
  }
  
  static public var defaultEndDate: Date {
    Calendar.current.date(byAdding: .year, value: 1, to: Date()) ??  Date(timeIntervalSinceNow: 31556952 * 1)
  }
  
  public static func migrate() {
    if Default.isFirstLaunch || isMigratedFromStandardDefaults { return }
    
    endDate = Default.endDate
    displayComponent = Default.displayComponent
    selectedCalIDs = Default.selectedCalendars
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
  
  @StandardDefault("selectedCalendars", defaultValue: [])
  static public var selectedCalendars: [String]
  
  @StandardDefault("isFirstLaunch", defaultValue: true)
  static public var isFirstLaunch: Bool
  
  @StandardDefault("showEventAsCard", defaultValue: true)
  static public var showEventAsCard: Bool
  
  //    @StandardDefault("confirmOnDelete", defaultValue: true)
  //    static public var confirmOnDelete: Bool
  
  //    @StandardDefault("firstAccessGranted", defaultValue: true)
  //    static public var isFirstLaunch: Bool
  
  static public var defaultEndDate: Date {
    Calendar.current.date(byAdding: .year, value: 1, to: Date()) ??  Date(timeIntervalSinceNow: 31556952 * 1)
  }
}

public class EventStore {
  static public var store = EKEventStore()
  
  static public func updateCalendars() {
    calendars = getCalendars()
    Preferences.shared.updateAllCalendars()
  }
  
  static public func getCalendars() -> [EKCalendar] {
    let calendars = store
      .calendars(for: .event)
      .sorted(by: { $0.type.rawValue < $1.type.rawValue } )
    
    if CDDefault.isFirstLaunch {
      CDDefault.selectedCalIDs = calendars.map { $0.calendarIdentifier }
      CDDefault.installedDate = Date()
      CDDefault.isFirstLaunch = false
    }
    
    return calendars
  }
  
  static public func save() {
    try? store.commit()
  }
  
  static public var calendars: [EKCalendar] = {
    getCalendars()
  }()
  
  //    static public var events: [EKEvent] = {
  //        return getEvents(inCalendars: Preferences.shared.selectedCalendars)
  //    }()
  
  static public func getEvents(inCalendars calendars: [EKCalendar]) -> [EKEvent] {
    guard !calendars.isEmpty else { return [] }
    
    let predicate = store.predicateForEvents(withStart: Date(),
                                             end: CDDefault.endDate,
                                             calendars: calendars)
    
    
    return store
      .events(matching: predicate)
      .distinct
      .sorted(by: { $0.occurrenceDate < $1.occurrenceDate})
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
  @Published public var isSelected: Bool
  
  public var name: String
  public var id: String
  public var color: Color
  
  public init(calendar: EKCalendar, isSelected: Bool = false) {
    self.id = calendar.calendarIdentifier
    self.name = calendar.title
    self.isSelected = isSelected
    self.color = calendar.color
  }
}



//public struct User: Codable {
//    let isPaidUser: Bool
//
//
//}
//
////userdefaults
//let defaults = UserDefaults.standard
//let user = User(isPaidUser: true)
//let encoder =   JSONEncoder()
//if let encodedUser = try? encoder.encode(user) {
//    defaults.set(encodedUser, forKey: "user")
//}
