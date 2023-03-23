//
//  CDSmallWidgetView.swift
//  CDWidgetExtension
//
//  Created by Asif on 16/02/23.
//

import EventKit
import SwiftUI

struct CDSmallWidgetView: View {
  var firstSevenEvents: [EKEvent]
  var eventsCount: Int
  var firstTwoEvents: [EKEvent] { Array(firstSevenEvents.prefix(2))}
  
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      TimerVStack(firstTwoEvents: firstTwoEvents)
      if eventsCount > 2 {
        MoreEventsStack(firstSevenEvents: firstSevenEvents, eventsCount: eventsCount)
      }
    }.padding(.leading, 10)
  }
}

struct TimerVStack: View {
  var firstTwoEvents: [EKEvent]
  
  var body: some View {
    VStack(spacing: 10) {
      ForEach(firstTwoEvents, id: \.eventIdentifier) { event in
        TimerDetailStack(event: event)
          .frame(width: 134, height: 46)
          .foregroundColor(event.color)
      }
    }
  }
}

struct TimerDetailStack: View {
  let event: EKEvent
  let helper = Helper()
  
  var days: Int { helper.getDays(targetTimeStamp: event.occurrenceDate.timeIntervalSince1970)}
  var date: Date { helper.getDate(targetTimeStamp: event.occurrenceDate.timeIntervalSince1970)}
  
  var body: some View {
    HStack {
      RoundedRectangle(cornerRadius: 5)
        .frame(width: 2, height: .infinity)
      VStack(alignment: .leading, spacing: 8) {
        Text(event.title)
          .font(.footnote)
          .fontWeight(.bold)
        timerStack
      }
    }
  }
  
  var timerStack: some View {
    HStack(alignment: .lastTextBaseline, spacing: 6) {
      daysVStack
      Text(date, style: .timer).font(Font.monospacedDigit(.callout)())
    }
  }
  
  var daysVStack: some View {
    HStack(alignment: .top, spacing: 3) {
      if days < 10 {
        HStack(spacing: 0) {
          Text("0").font(.footnote)
          Text(String(days)).font(.footnote)
        }
      } else {
        Text(String(days)).font(.footnote)
      }
      if days < 2 {
        Text("day").font(.system(size: 6))
      } else {
        Text("days").font(.system(size: 6))
      }
    }
  }
}

 struct MoreEventsStack: View {
  var firstSevenEvents: [EKEvent]
  var eventsCount: Int
  var nextEvents: [EKEvent] { Array(firstSevenEvents.dropFirst(2))}
  var nextEventsCount: Int { eventsCount - 2}
  
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      firstHStack
      secondHStack
    }
  }
  
  var firstHStack: some View {
    HStack(spacing: 3) {
      ForEach(nextEvents, id: \.eventIdentifier) { event in
        RoundedRectangle(cornerRadius: 5)
          .foregroundColor(event.color)
          .frame(width: 2, height: 12)
      }
    }
  }
  
  var secondHStack: some View {
    HStack(alignment: .firstTextBaseline, spacing: 5) {
      Text("\(nextEventsCount) more events")
        .foregroundColor(.secondary)
        .font(.caption)
      Image("MoreEvents")
        .font(.caption)
    }
  }
}

struct CDSmallWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    CDSmallWidgetView(firstSevenEvents: [], eventsCount: 1)
  }
}
