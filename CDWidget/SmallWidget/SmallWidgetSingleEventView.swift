//
//  SmallWidgetSingleEventView.swift
//  CDWidgetExtension
//
//  Created by Asif on 21/02/23.
//

import SwiftUI
import EventKit

struct SmallWidgetSingleEventView: View {
  var firstEvent: EKEvent?
  
  var body: some View {
    HStack(alignment: .top,spacing: 7) {
      HStack{
        RoundedRectangle(cornerRadius: 5)
          .foregroundColor(firstEvent!.color)
          .frame(width: 2, height: 108)
      }
      
      VStack(alignment: .leading, spacing: 9) {
        Text(firstEvent!.title)
          .font(.callout)
          .foregroundColor(firstEvent!.color)
          .fontWeight(.bold)
        
        middleStack
          
        TimerDetailStack(event: firstEvent!).timerStack
          .foregroundColor(firstEvent!.color)
      }
    }.padding(.leading,20)
  }
  
  var middleStack: some View {
    VStack(alignment: .leading, spacing: 7){
      firstDetailStack
      
      if(firstEvent!.alarmsString != ""){
        secondDetailStack
      }
      
      if(firstEvent!.urlString != ""){
        thirdDetailStack
      }
    }.foregroundColor(.secondary)
  }
  
  var firstDetailStack: some View {
    HStack (alignment: .center,spacing: 8) {
      Image("calendar_icon")
        .resizable()
        .frame(width: 12, height: 12)
      Text(firstEvent!.occurrenceDate.toString(inFormat: "MMM d, hh.mm a"))
        .font(.caption2)
    }
  }
  
  var secondDetailStack: some View {
    HStack(alignment: .bottom,spacing: 5) {
      Image(systemName: "clock")
        .imageScale(.small)
      Text(firstEvent!.alarmsString)
        .font(.caption2)
    }
  }
  
  var thirdDetailStack : some View {
    HStack(alignment: .firstTextBaseline,spacing: 5) {
      Image(systemName: "person.fill")
        .imageScale(.small)
      Text(firstEvent!.urlString)
        .font(.caption2)
    }
  }
}

struct SmallWidgetSingleEventView_Previews: PreviewProvider {
  static var previews: some View {
    SmallWidgetSingleEventView()
  }
}
