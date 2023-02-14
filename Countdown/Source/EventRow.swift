//
//  EventRow.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import SwiftUI
import EventKit
import SwiftDate
import SwiftyUserInterface
//import CountdownKit

struct EventRow: View {
  
  @ObservedObject var preferences = Preferences.shared
  @State var event: EKEvent
  @ObservedObject var favModel: FavoriteModel
  
  init(event: EKEvent) {
    self._event = State(initialValue: event)
    self.favModel = FavoriteModel(event: event)
  }
  
  var body: some View {
    Button(action: {
      Router.shared.showDetail(for: self.$event)
    }, label: {
      Group {
        if preferences.showEventAsCard {
          eventCard.contentShape(RoundedRectangle(cornerRadius: .small))
          //                        .transition(AnyTransition.scale.combined(with: .opacity))
        } else {
          eventStack.contentShape(Rectangle())
          //                        .transition(AnyTransition.scale.combined(with: .opacity))
        }
      }
      
    })
    .buttonStyle(TappableButton(isRoundedCorners: $preferences.showEventAsCard, cornerRadius: .small))
    //            .contextMenu(menuItems: {
    //                VStack {
    //                    Button(action: favModel.toggle, label: {
    //                        if favModel.isFavEvent {
    //                            Text("Remove from favorites")
    //                            Image(systemName: "heart")
    //                        } else {
    //                            Text("Add to favorites")
    //                            Image(systemName: "heart.fill")
    //                        }
    //                    })
    //                    Button(action: {
    //                        "Edit Event".log()
    //                    }, label: {
    //                        Text("Edit")
    //                        Image(systemName: "square.and.pencil")
    //                    })
    //                    Button(action: {
    //                        "Delete Event".log()
    //                    }, label: {
    //                        Text("Delete")
    //                        Image(systemName: "trash")
    //                    })
    //                }
    //            })
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
        //                    .foregroundColor(event.color)
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
  }
  
  var eventTitle: some View {
    Group {
      if preferences.searchText.isEmpty {
        Text(event.title)
      } else {
        HighlightedText(event.title, matching: preferences.searchText)
      }
    }
  }
  
  var eventStack: some View {
    HStack {
      
      if preferences.isPaidUser {
        favModel.image
          .font(.footnote)
          .foregroundColor(event.color)
          .onTapGesture { self.favModel.toggle() }
      } else {
        Circle()
          .fill(event.color)
          .frame(width: .small, height: .small)
      }
      
      
      eventTitle
        .multilineTextAlignment(.leading)
      //                .padding(.leading)
      Spacer()
      Text(event.difference(in: preferences.calendarComponent))
      Image(systemName: "chevron.right")
        .imageScale(.small)
        .foregroundColor(Color(.quaternaryLabel))
    }
    .padding(EdgeInsets(top: .small, leading: .medium, bottom: .small, trailing: .small))
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

//struct EventRow_Previews: PreviewProvider {
//    static var previews: some View {
//        EventRow()
//    }
//}

