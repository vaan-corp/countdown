//
//  CDWidget.swift
//  CDWidget
//
//  Created by Asif on 15/02/23.
//

import WidgetKit
import SwiftUI
import Intents
import EventKit

struct Provider: IntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), configuration: ConfigurationIntent())
  }
  
  func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let entry = SimpleEntry(date: Date(), configuration: configuration)
    completion(entry)
  }
  
  func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
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

struct CDWidgetEntryView : View {
  var entry: Provider.Entry
  let kind: String
  var events: [EKEvent]
  @Environment(\.widgetFamily) var family: WidgetFamily
  
  var body: some View {
    switch family {
    case .systemSmall:
      if(events.count == 0){
        NoEventsView(kind: kind)
      } else if(events.count == 1){
        //TODO: add small widget with single event
        Text("small widget single event")
      }
      else {
        CDSmallWidgetView(events: events)
      }
    default:
      Text("Widget not supported yet")
    }
  }
}

struct FavEventsWidget: Widget {

  let kind : String = "favEvents"
  var favEvents: [EKEvent] { Preferences.shared.favoriteEvents}
  var firstSevenFavEvents: [EKEvent] { Array(favEvents.prefix(7))}
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: self.kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      CDWidgetEntryView(entry: entry, kind: kind, events: favEvents)
    }
    .configurationDisplayName("Favorite Events")
    .description("Your Favorite Events.")
    .supportedFamilies([.systemSmall])
  }
}

struct AllEventsWidget: Widget {

  let kind : String = "allEvents"
  var allEvents: [EKEvent] { Preferences.shared.events}
  var allEventsCount :Int { allEvents.count}
  var firstSevenAllEvents: [EKEvent] { Array(allEvents.prefix(7))}
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      CDWidgetEntryView(entry: entry, kind: kind, events: allEvents)
    }
    .configurationDisplayName("All Events")
    .description("Your Upcoming Events.")
    .supportedFamilies([.systemSmall])
  }
}

struct CDWidget_Previews: PreviewProvider {
  static var previews: some View {
    CDWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()), kind: "", events: [])
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
