//
//  CDWidget.swift
//  CDWidget
//
//  Created by Asif on 15/02/23.
//

import EventKit
import Intents
import SwiftUI
import WidgetKit

struct Provider: IntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), configuration: ConfigurationIntent())
  }
  
  func getSnapshot(
    for configuration: ConfigurationIntent,
    in context: Context,
    completion: @escaping (SimpleEntry) -> Void
  ) {
    let entry = SimpleEntry(date: Date(), configuration: configuration)
    completion(entry)
  }
  
  func getTimeline(
    for configuration: ConfigurationIntent,
    in context: Context,
    completion: @escaping (Timeline<Entry>) -> Void
  ) {
    var entries: [SimpleEntry] = []
    
    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, configuration: configuration)
      entries.append(entry)
    }
    
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationIntent
}

struct CDWidgetEntryView: View {
  var entry: Provider.Entry
  let kind: String
  var firstSevenEvents: [EKEvent]
  var eventsCount: Int
  @Environment(\.widgetFamily) var family: WidgetFamily
  
  var body: some View {
    switch family {
    case .systemSmall:
      if eventsCount == 0 {
        NoEventsView(kind: kind)
      } else if eventsCount == 1 {
        if let event = firstSevenEvents.first {
          SmallWidgetSingleEventView(event: event)
        }
      } else {
        SmallWidgetMultipleEventsView(firstSevenEvents: firstSevenEvents, eventsCount: eventsCount)
      }
    case .systemMedium:
      if eventsCount == 0 {
        NoEventsView(kind: kind)
      } else if eventsCount <= 4 {
        if let event = firstSevenEvents.first {
          MediumWidgetSingleEventView(event: event)
        }
      } else {
        MediumWidgetMultipleEventsView(firstSevenEvents: firstSevenEvents, eventsCount: eventsCount, kind: kind)
      }
    default:
      Text("Widget not supported yet")
    }
  }
}

struct FavEventsWidget: Widget {
  let kind: String = "favEvents"
  var favEvents: [EKEvent] { Preferences.shared.favoriteEvents}
  var favEventsCount: Int { favEvents.count}
  var firstSevenEvents: [EKEvent] { Array(favEvents.prefix(7))}
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: self.kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      CDWidgetEntryView(entry: entry, kind: kind, firstSevenEvents: firstSevenEvents, eventsCount: favEventsCount)
    }
    .configurationDisplayName("Favorite Events")
    .description("Add favorties in the app to see countdown quickly on your home screen")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct AllEventsWidget: Widget {
  let kind: String = "allEvents"
  var allEvents: [EKEvent] { Preferences.shared.events}
  var allEventsCount: Int { allEvents.count}
  var firstSevenEvents: [EKEvent] { Array(allEvents.prefix(7))}
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      CDWidgetEntryView(entry: entry, kind: kind, firstSevenEvents: firstSevenEvents, eventsCount: allEventsCount)
    }
    .configurationDisplayName("Upcoming events")
    .description("See countdown for all events on your calendar")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct CDWidget_Previews: PreviewProvider {
  static var previews: some View {
    CDWidgetEntryView(
      entry: SimpleEntry(date: Date(),
      configuration: ConfigurationIntent()), kind: "",
      firstSevenEvents: [], eventsCount: 7
    )
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
