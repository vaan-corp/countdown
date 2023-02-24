//
//  EventDetail.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import Combine
import EventKit
import SwiftUI
import SwiftyUserInterface

struct EventDetail: View {
  @Environment(\.presentationMode) var presentationMode
  
  @ObservedObject var preferences = Preferences.shared
  @Binding var event: EKEvent
  @State var isDeleted = false
  @State var timeGap: TimeGap
  @State var showsEditEventView = false
  
  @ObservedObject var favModel: FavoriteModel
  
  let timer: Publishers.Autoconnect<Timer.TimerPublisher> = Timer.secondlyPublisher
  
  init(event: Binding<EKEvent>) {
    self._event = event
    self._timeGap = State(initialValue: event.wrappedValue.occurrenceDate.timeGap)
    self.favModel = FavoriteModel(event: event.wrappedValue)
  }
  
  var body: some View {
    viewStack
      .embedInScrollView()
      .accentColor(.appTintColor)
      .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
      .navigationBarTitle("\(event.title)", displayMode: .inline)
      .navigationBarItems(trailing: editButton)
  }
  
  //    var trailingItems: some View {
  //        HStack {
  //            favButton
  //            editButton
  //        }
  //    }
  
  var favButton: some View {
    Button(action: favModel.toggle, label: {
      self.favModel.image
        .imageScale(.large)
        .foregroundColor(.red)
    })
  }
  
  var viewStack: some View {
    VStack(spacing: .medium) {
      if event.occurrenceDate <= Date() || timeGap.isNegative {
        eventStarted
      } else {
        remainingTime
      }
      
      //            zCard
      customDetailCard
        .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
        .padding(.top, .averageTouchSize)
      Spacer()
    }
  }
  
  //    var zCard: some View {
  //        ZStack(alignment: .topTrailing) {
  //            customDetailCard
  //            .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
  //            favImage
  //                .offset(x: -.averageTouchSize, y: -.large)
  //        }
  //        .padding(.top, .averageTouchSize)
  //    }
  
  var customDetailCard: some View {
    VStack(alignment: .leading, spacing: .medium) {
      HStack(alignment: .center, spacing: .medium) {
        Text("Event details: ")
        //                    .foregroundColor(.secondary)
          .secondaryText()
        Spacer()
        if preferences.isPaidUser {
          favButton
        }
      }
      
      HStack(spacing: .medium) {
        Image(systemName: "clock.fill").foregroundColor(.orange)
        Text(event.occurrenceDate.toString(inFormat: "EEEE, d MMM yyyy, h:mm a"))
      }
      
      HStack(spacing: .medium) {
        Image(systemName: "calendar").foregroundColor(event.color)
        Text(event.calendar.title)
      }
      
      if !event.attendeeString.isEmpty {
        HStack(spacing: .medium) {
          Image(systemName: "person.fill").foregroundColor(.purple)
          Text(event.attendeeString)
        }
      }
      
      if !event.locationString.isEmpty {
        HStack(spacing: .medium) {
          Image(systemName: "mappin.and.ellipse").foregroundColor(.red)
          Text(event.locationString)
        }
      }
      
      if !event.alarmsString.isEmpty {
        HStack(spacing: .medium) {
          Image(systemName: "alarm.fill").foregroundColor(.green)
          Text(event.alarmsString)
        }
      }
      
      if event.hasNotes {
        HStack(spacing: .medium) {
          Image(systemName: "square.and.pencil").foregroundColor(.yellow)
          Text(event.notes!.trimmingCharacters(in: .whitespacesAndNewlines))
        }
      }
      
      if !event.urlString.isEmpty {
        HStack(spacing: .medium) {
          Image(systemName: "link").foregroundColor(.blue)
          Button(event.urlString) {
            UIApplication.shared.open(self.event.url!, options: [:], completionHandler: nil)
          }.accentColor(.blue)
        }
      }
    }.padding(.horizontal, .medium)
  }
  
  //    var favImage: some View {
  //        ZStack {
  //            Circle()
  //                .stroke(lineWidth: 1)
  //                .foregroundColor(Color.red.opacity(0.5))
  //                .frame(width: .averageTouchSize * 0.8, height: .averageTouchSize * 0.8)
  //            favButton.offset(x: 0, y: 1)
  //        }
  //    }
  
  //    var personImageString: String {
  //        if event.attendees!.count == 1 {
  //            return "person.fill"
  //        } else if event.attendees!.count == 2 {
  //            return "person.2.fill"
  //        }
  //
  //        return "person.3.fill"
  //    }
  
  var eventStarted: some View {
    VStack(spacing: .small) {
      //            Text("🎊")
      //                .font(.system(size: .imageSize))
      //                .padding(.top, .imageSize * 2)
      Text("started").foregroundColor(.secondary)
      Text(event.occurrenceDate.relativeTime())
        .font(.title)
      //            Text("🎉")
      //                .font(.system(size: .imageSize))
    }
    .padding(.top, .averageTouchSize)
  }
  
  public var remainingTime: some View {
    VStack {
      if timeGap.days > 0 {
        UnitView(value: String(format: "%02d", timeGap.days), unit: "days")
          .padding(.averageTouchSize)
      }
      
      HStack(spacing: .small) {
        Spacer()
        UnitView(value: String(format: "%02d", timeGap.hours), unit: "hours")
        Spacer()
        UnitView(value: String(format: "%02d", timeGap.minutes), unit: "minutes")
        Spacer()
        UnitView(value: String(format: "%02d", timeGap.seconds), unit: "seconds")
        Spacer()
      }.padding(.top, (timeGap.days > 0 ? .zero : .imageSize))
    }.onReceive(timer) { _ in
      self.timeGap = self.event.occurrenceDate.timeGap
    }
  }
  
  var editButton: some View {
    Button(action: {
      self.showsEditEventView = true
    }, label: {
      Text("Edit")
      //            Image(systemName: "pencil")
      //                .imageScale(.large)
    })
    .disabled(!event.calendar.allowsContentModifications)
    .sheet(isPresented: $showsEditEventView, onDismiss: checkChangeInEvent,
           content: eventEditView)
  }
  
  func checkChangeInEvent() {
    self.timeGap = self.event.occurrenceDate.timeGap
    if isDeleted {
      presentationMode.wrappedValue.dismiss()
    }
  }
  
  func eventEditView() -> some View {
    EditEventVC(event: $event, isDeleted: $isDeleted)
    //        EKEventActionView(event: self.event)
  }
}

extension TimeGap {
  var isNegative: Bool {
    if seconds < 0 { return true }
    if minutes < 0 { return true }
    if hours < 0 { return true }
    if days < 0 { return true }
    
    return false
  }
}

struct UnitView: View {
  var value: String
  var unit: String
  
  var body: some View {
    VStack {
      Text(value)
        .font(.system(size: .averageTouchSize * 1.25 ))
        .frame(minWidth: minimumSize, minHeight: minimumSize)
        .background(
          Color(.secondarySystemGroupedBackground)
            .frame(width: minimumSize * 1.5, height: minimumSize * 1.5)
            .clipShape(Circle())
          //                        .shadow(radius: 2)
        )
        .padding(.bottom, minimumSize * 0.3)
      
      Text(unit).foregroundColor(.secondary)
    }
  }
  
  var minimumSize: CGFloat {
    if value.count <= 3 { return .imageSize }
    
    return .imageSize * 0.35 * CGFloat(value.count)
  }
}

struct EventDetail_Previews: PreviewProvider {
  static var previews: some View {
    UnitView(value: "895", unit: "days")
  }
}
