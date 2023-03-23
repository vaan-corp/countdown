//
//  CDMediumWidgetView.swift
//  CDWidgetExtension
//
//  Created by Asif on 13/03/23.
//

import EventKit
import SwiftUI

struct CDMediumWidgetView: View {
  var firstSevenEvents: [EKEvent]
  var eventsCount: Int
  var firstTwoEvents: [EKEvent] { Array(firstSevenEvents.prefix(2))}
  var nextEvents: [EKEvent] { Array(firstSevenEvents.dropFirst(2))}
  let kind: String
  var image: Image { kind == "favEvents" ? Image(systemName: "heart.fill") : Image("countdown")}
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack(alignment: .center, spacing: 20) {
        TimerVStack(firstTwoEvents: firstTwoEvents)
        secondVStack
        thirdVStack
      }
    }
    secondHStack
  }
  
  var secondVStack: some View {
    VStack(alignment: .leading, spacing: 7) {
      ForEach(nextEvents, id: \.eventIdentifier) { event in
        HStack {
          RoundedRectangle(cornerRadius: 5)
            .frame(width: 2, height: 12)
          Text(event.title)
            .font(.caption2)
            .fontWeight(.bold)
        }
        .foregroundColor(.purple)
      }
    }
  }
  
  var thirdVStack: some View {
    VStack(spacing: 5) {
      ForEach(nextEvents, id: \.eventIdentifier) { event in
        TimerDetailStack(event: event).daysVStack
          .foregroundColor(event.color)
      }
    }
  }
  
  var secondHStack: some View {
    HStack {
      HStack(alignment: .center, spacing: 7) {
        image
          .foregroundColor(.red)
        
        Text(kind == "favEvents" ? "Favorite events" : "Upcoming events")
          .foregroundColor(Color.gray)
          .font(.custom("font", size: 11, relativeTo: .caption2))
      } .padding(.leading, 12)
      Spacer()
      MoreEventsStack(firstSevenEvents: firstSevenEvents, eventsCount: eventsCount)
        .padding(.trailing, 20)
    }
    .frame(height: 16)
  }
}

struct CDMediumWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    CDMediumWidgetView(firstSevenEvents: [], eventsCount: 1, kind: "")
  }
}
