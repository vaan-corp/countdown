//
//  SmallWidgetSingleEventView.swift
//  CDWidgetExtension
//
//  Created by Asif on 21/02/23.
//

import SwiftUI
import EventKit

struct SmallWidgetSingleEventView: View {
  var event: EKEvent
  
  var body: some View {
    HStack(alignment: .top,spacing: 7) {
      HStack{
        RoundedRectangle(cornerRadius: 5)
          .foregroundColor(event.color)
          .frame(width: 2, height: 108)
      }
      
      VStack(alignment: .leading, spacing: 9) {
        Text(event.title)
          .font(.callout)
          .foregroundColor(event.color)
          .fontWeight(.bold)
        
        middleStack
        
        TimerDetailStack(event: event).timerStack
          .foregroundColor(event.color)
      }
    }.padding(.leading,20)
  }
  
  var middleStack: some View {
    VStack(alignment: .leading, spacing: 7){
      firstDetailStack
      
      if(!event.alarmsString.isEmpty){
        secondDetailStack
      }
      
      if(!event.urlString.isEmpty){
        thirdDetailStack
      }
    }.foregroundColor(.secondary)
  }
  
  var firstDetailStack: some View {
    HStack (alignment: .center,spacing: 8) {
      Image("calendar_icon")
        .resizable()
        .frame(width: 12, height: 12)
      HStack(spacing:2){
        Text(event.occurrenceDate.formatted(.dateTime.day().month()))
        Text(",")
        Text(event.occurrenceDate, style: .time)
      }
        .font(.caption2)
    }
  }
  
  var secondDetailStack: some View {
    HStack(alignment: .bottom,spacing: 5) {
      Image(systemName: "clock")
        .imageScale(.small)
      Text(event.alarmsString)
        .font(.caption2)
    }
  }
  
  var thirdDetailStack : some View {
    HStack(alignment: .firstTextBaseline,spacing: 5) {
      Image(systemName: "person.fill")
        .imageScale(.small)
      Text(event.urlString)
        .font(.caption2)
    }
  }
}

