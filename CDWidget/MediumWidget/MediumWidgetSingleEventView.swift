//
//  MediumWidgetSingleEventView.swift
//  CDWidgetExtension
//
//  Created by Asif on 23/03/23.
//
import EventKit
import SwiftUI

struct MediumWidgetSingleEventView: View {
  var event: EKEvent
  let helper = Helper()

  var days: Int { helper.getDays(targetTimeStamp: event.occurrenceDate.timeIntervalSince1970)}
  var date: Date { helper.getDate(targetTimeStamp: event.occurrenceDate.timeIntervalSince1970)}
  
  var body: some View {
    HStack(alignment: .top, spacing: 7) {
      HStack {
        RoundedRectangle(cornerRadius: 5)
          .foregroundColor(event.color)
          .frame(width: 2, height: 100)
      }

      VStack(alignment: .leading, spacing: 9) {
        Text(event.title)
          .font(.callout)
          .foregroundColor(event.color)
          .fontWeight(.bold)
        
        SmallWidgetSingleEventView(event: event).middleStack
      }
      
      VStack(alignment: .leading) {
        daysVStack
        timer
      }
      .foregroundColor(event.color)
      .padding(.leading, 20)
    }
    .padding(.leading, 20)
  }
  
  var daysVStack: some View {
    HStack(alignment: .top, spacing: 3) {
      if days < 10 {
        HStack(spacing: 0) {
          Text("0").font(.largeTitle)
          Text(String(days)).font(.largeTitle)
        }
      } else {
        Text(String(days)).font(.largeTitle)
      }
      if days < 2 {
        Text("day").font(.caption)
      } else {
        Text("days").font(.caption)
      }
    }
  }
  
  var timer: some View {
    Text(date, style: .timer).font(Font.monospacedDigit(.largeTitle)())
  }
}
