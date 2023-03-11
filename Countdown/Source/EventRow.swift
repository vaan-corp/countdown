//
//  EventRow.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import EventKit
import SwiftDate
import SwiftUI

struct EventRow: View {
  @ObservedObject var preferences = Preferences.shared
  @State var event: EKEvent
  @ObservedObject var favModel: FavoriteModel
  @Binding var searchText: String
  
  init(event: EKEvent, searchText: Binding<String>) {
    self._event = State(initialValue: event)
    self.favModel = FavoriteModel(event: event)
    _searchText = searchText
  }

  var body: some View {
    NavigationLink {
      EventDetail(event: self.$event)
    } label: {
      Group {
        eventCard.contentShape(RoundedRectangle(cornerRadius: .small))
      }
    }
    .listRowBackground(preferences.showEventAsCard ?  Color(.systemGroupedBackground) : .clear)
    .listRowInsets(insets)
  }
  
  var insets: EdgeInsets {
    if preferences.showEventAsCard {
      return EdgeInsets(top: .small, leading: .medium, bottom: .small, trailing: .medium)
    }
    
    return EdgeInsets(top: .zero, leading: .zero, bottom: .zero, trailing: .zero)
  }
  
  var eventCard: some View {
    VStack(alignment: .leading, spacing: .small) {
      self.firstHstack
      self.secondHstack
    }
    .padding(EdgeInsets(top: .small, leading: .medium, bottom: .small, trailing: .medium))
    .background(
      RoundedRectangle(cornerRadius: .small)
        .fill(Color(.secondarySystemGroupedBackground))
    )
    .padding(.horizontal)
  }
  
  var firstHstack: some View {
    HStack {
      Image(systemName: "calendar")
      Text(event.calendar.title)
      Spacer()
      Text(eventDate)
      if preferences.isPaidUser {
        favModel.image
          .foregroundColor(.red)
          .onTapGesture { self.favModel.toggle() }
      } else {
        Image(systemName: "clock")
      }
    }
    .secondaryText()
  }

  var secondHstack: some View {
    HStack {
      eventTitle
        .multilineTextAlignment(.leading)
      Spacer()
      Text(event.difference(in: preferences.calendarComponent))
        .makeTag(with: event.color.opacity(0.5))
    }
    .foregroundColor(.primary)
  }
  
  var eventTitle: some View {
    Group {
      if searchText.isEmpty {
        Text(event.title)
      } else {
        Text(highlightedText(event.title, matching: searchText))
      }
    }
  }

  func highlightedText(_ text: String, matching: String) -> AttributedString {
    let attributedString = NSMutableAttributedString(string: text)
    let range = (text as NSString).range(of: matching, options: .caseInsensitive)
    attributedString.addAttribute(.foregroundColor, value: UIColor.red, range: range)
    return AttributedString(attributedString)
  }

  var eventDate: String {
    let daysLeft = event.occurrenceDate.timeGap.days
    
    // check for the most common cases first
    if daysLeft >= 7 {
      // not in a week but in a year
      if daysLeft < 365 {
        return event.occurrenceDate.toString(inFormat: "MMM d")
      }
      
      // in the next years
      return event.occurrenceDate.toString(inFormat: "MMM d, yyyy")
    }
    
    if Calendar.current.isDateInToday(event.occurrenceDate) {
      return "Today, " + event.occurrenceDate.toString(inFormat: "h:mm a")
    } else if Calendar.current.isDateInTomorrow(event.occurrenceDate) {
      return "Tomorrow, " + (event.occurrenceDate.toString(inFormat: "h:mm a"))
    }
    
    // some day after tomorrow in the next 7 days
    return event.occurrenceDate.toString(inFormat: "MMM d, h:mm a")
  }
}
