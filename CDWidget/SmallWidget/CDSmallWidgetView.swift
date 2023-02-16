//
//  CDSmallWidgetView.swift
//  CDWidgetExtension
//
//  Created by Asif on 16/02/23.
//

import SwiftUI
import EventKit

struct CDSmallWidgetView: View {
  var body: some View {
    VStack(spacing: 18){
      TimerVStack()
      MoreEventsStack()
    }
  }
}

private struct TimerVStack: View {
  var body: some View {
    VStack(spacing: 10) {
      ForEach(Events().firstTwoFavoriteEvents, id: \.eventIdentifier) { event in
        TimerDetailStack(event: event)
          .frame(width: 134, height: 42)
          .foregroundColor(event.color)
      }
    }
    .padding(.leading, 10)
  }
}

private struct TimerDetailStack: View {
  let event : EKEvent
  
  init(event: EKEvent) {
    self.event = event
  }
  
  var days: Int { Helper().getDays(targetTimeStamp: event.occurrenceDate.timeIntervalSince1970)}
  var date: Date { Helper().getDate(targetTimeStamp: event.occurrenceDate.timeIntervalSince1970)}
  
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
      HStack(alignment: .top, spacing: 3) {
        if(days < 10) {
          HStack(spacing: 0){
            Text("0").font(.callout)
            Text(String(days)).font(.callout)
          }
        } else {
          Text(String(days)).font(.callout)
        }
        if(days < 2){
          Text("day").font(.system(size: 6))
        } else {
          Text("days").font(.system(size: 6))
        }
      }
      Text(date, style: .timer).font(Font.monospacedDigit(.callout)())
    }
  }
}

private struct MoreEventsStack: View {
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6){
      firstHStack
      secondHStack
    }
  }
  
  var firstHStack: some View {
    HStack(spacing: 3){
      ForEach(Events().nextFiveFavoriteEvents, id: \.eventIdentifier){ event in
        RoundedRectangle(cornerRadius: 5)
          .foregroundColor(event.color)
          .frame(width: 2,height: 12)
      }
    }
  }
  
  var secondHStack: some View {
    HStack(alignment: .firstTextBaseline, spacing: 5){
      Text("\(Events().nextFavoriteEventsCount) more events")
        .foregroundColor(.secondary)
        .font(.caption)
      Image("MoreEvents")
        .font(.caption)
    }
  }
}

struct CDSmallWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    CDSmallWidgetView()
  }
}
