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
  var firstSevenEvents: [EKEvent]
  var eventsCount: Int
  @Environment(\.widgetFamily) var family: WidgetFamily
  
  var body: some View {
    switch family {
    case .systemSmall:
      if(eventsCount == 0){
        NoEventsView(kind: kind)
      } else if(eventsCount == 1){
        //TODO: add small widget with single event
        Text("small widget single event")
      }
      else {
        CDSmallWidgetView(firstSevenEvents: firstSevenEvents, eventsCount: eventsCount)
      }
    default:
      Text("Widget not supported yet")
    }
  }
}

struct FavEventsWidget: Widget {

  let kind : String = "favEvents"
  var favEvents: [EKEvent] { Preferences.shared.favoriteEvents}
  var favEventsCount: Int { favEvents.count}
  var firstSevenEvents: [EKEvent] { Array(favEvents.prefix(7))}
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: self.kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      CDWidgetEntryView(entry: entry, kind: kind, firstSevenEvents: firstSevenEvents, eventsCount: favEventsCount)
    }
    .configurationDisplayName("Favorite Events")
    .description("Add favorties in the app to see countdown quickly on your home screen")
    .supportedFamilies([.systemSmall])
  }
}

struct AllEventsWidget: Widget {

  let kind : String = "allEvents"
  var allEvents: [EKEvent] { Preferences.shared.events}
  var allEventsCount :Int { allEvents.count}
  var firstSevenEvents: [EKEvent] { Array(allEvents.prefix(7))}
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      CDWidgetEntryView(entry: entry, kind: kind, firstSevenEvents: firstSevenEvents, eventsCount: allEventsCount)
    }
    .configurationDisplayName("Upcoming events")
    .description("See countdown for all events on your calendar")
    .supportedFamilies([.systemSmall])
  }
}

struct CDWidget_Previews: PreviewProvider {
  static var previews: some View {
    CDWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()), kind: "", firstSevenEvents: [], eventsCount: 7)
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
