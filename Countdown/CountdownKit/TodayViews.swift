//
//  TodayViews.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import Combine
import CoreData
import EventKit
import MIDataStore
import SwiftUI

public enum CDWidget {
  case favorites
  case upcomingEvents
  
  var noEventsString: String {
    switch self {
    case .favorites: return "Kindly select more favorites in the app to view them here."
    case .upcomingEvents: return "Please update your calendar settings to view upcoming events here."
    }
  }
  
  var screenName: String {
    switch self {
    case .favorites: return "home"
    case .upcomingEvents: return "settings"
    }
  }
}

public protocol TodayViewProtocol: ObservableObject {
  var isDefaultSize: Bool { get set }
  var displayEventsCount: Int { get }
  var firstFourEvents: [EKEvent] { get set }
  var source: CDWidget { get }
  
  func updateEvents()
  func openApp(screenName: String)
}

extension TodayViewProtocol {
  public func checkAndUpdateEvents() {
    guard CDDefault.isPaidUser else {
      firstFourEvents = []
      return
    }
    
    updateEvents()
  }
}

public struct TodayView<Model: TodayViewProtocol>: View {
  @ObservedObject var model: Model
  
  @State var timeGap0: TimeGap
  @State var timeGap1: TimeGap
  @State var timeGap2: TimeGap
  @State var timeGap3: TimeGap
  
  let timer: Publishers.Autoconnect<Timer.TimerPublisher> = Timer.secondlyPublisher
  
  public init(model: Model) {
    self.model = model
    self._timeGap0 = State(initialValue: model.firstFourEvents[safe: 0]?.occurrenceDate.timeGap ?? TimeGap())
    self._timeGap1 = State(initialValue: model.firstFourEvents[safe: 1]?.occurrenceDate.timeGap ?? TimeGap())
    self._timeGap2 = State(initialValue: model.firstFourEvents[safe: 2]?.occurrenceDate.timeGap ?? TimeGap())
    self._timeGap3 = State(initialValue: model.firstFourEvents[safe: 3]?.occurrenceDate.timeGap ?? TimeGap())
  }
  
  @ViewBuilder public var body: some View {
    if !CDDefault.isPaidUser {
      Text("Kindly upgrade to Countdown PRO to start using widgets\n\nTap to open")
        .multilineTextAlignment(.center)
        .onTapGesture {
          self.model.openApp(screenName: "iap")
        }
    } else if model.firstFourEvents.isEmpty {
      Text("\(model.source.noEventsString)\n\nTap to open")
        .multilineTextAlignment(.center)
        .onTapGesture {
          self.model.openApp(screenName: self.model.source.screenName)
        }
    } else {
      ScrollView {
        eventsStack
      }
    }
  }
  
  var eventsCount: Int { model.firstFourEvents.count }
  
  var eventsStack: some View {
    VStack {
      firstEvent
        .transition(AnyTransition.opacity)
      if !model.isDefaultSize {
        if eventsCount > 1 {
          eventGroup
        } else {
          placeholderView
        }
      }
    }
  }
  
  var eventGroup: some View {
    Group {
      Divider()
      if eventsCount <= 2 {
        secondEvent
      } else if eventsCount <= 3 {
        secondEvent
        Divider()
        thirdEvent
      } else if eventsCount <= 4 {
        secondEvent
        Divider()
        thirdEvent
        Divider()
        fourthEvent
      }
      if eventsCount < 4 {
        placeholderView
      }
    }
    .transition(AnyTransition.opacity)
  }
  
  var placeholderView: some View {
    VStack {
      Text("Open app to select more favorites")
    }
    .frame(height: 140)
    .contentShape(Rectangle())
    .onTapGesture {
      self.model.openApp(screenName: "home")
    }
  }
  
  var firstEvent: some View {
    self.card(for: model.firstFourEvents[0], with: $timeGap0)
  }
  
  var secondEvent: some View {
    self.card(for: model.firstFourEvents[1], with: $timeGap1)
  }
  
  var thirdEvent: some View {
    self.card(for: model.firstFourEvents[2], with: $timeGap2)
  }
  
  var fourthEvent: some View {
    self.card(for: model.firstFourEvents[3], with: $timeGap3)
  }
  
  func card(for event: EKEvent, with timeGap: Binding<TimeGap>) -> some View {
    EventCountDownCard(event: event, timeGap: timeGap)
      .contentShape(Rectangle())
      .onTapGesture {
        self.model.openApp(screenName: "eventID=\(event.eventIdentifier ?? "")")
      }
      .onReceive(timer) { time in
        guard event.occurrenceDate > time else {
          self.model.updateEvents()
          return
        }
        
        timeGap.wrappedValue = event.occurrenceDate.timeGap
      }
  }
}

// struct Today_Preview: PreviewProvider {
//    static var previews: some View {
//        TodayView(model: UpcomingEventsModel())
//    }
// }

// might be requried in future if we show only one event
// public struct CDEventCard: View {
//    @State var timeGap: TimeGap
//
//    var event: EKEvent
//    let timer: Publishers.Autoconnect<Timer.TimerPublisher> = Timer.secondlyPublisher
//
//    public init(event: EKEvent) {
//        self.event = event
//        self._timeGap = State(initialValue: event.occurrenceDate.timeGap)
//    }
//
//    public var body: some View {
//        EventCountDownCard(event: event, timeGap: $timeGap)
//            .onReceive(timer) { _ in
//                self.timeGap = self.event.occurrenceDate.timeGap
//        }
//    }
// }

public struct EventCountDownCard: View {
  var event: EKEvent
  
  @Binding var timeGap: TimeGap
  
  public init(event: EKEvent, timeGap: Binding<TimeGap>) {
    self.event = event
    self._timeGap = timeGap
  }
  
  public var body: some View {
    VStack {
      titleStack
      remainingTime
    }
    .padding(EdgeInsets(top: .small, leading: .medium, bottom: .small, trailing: .medium))
  }
  
  var titleStack: some View {
    HStack {
      Image(systemName: "calendar")
        .foregroundColor(event.color)
      Text(event.title)
        .multilineTextAlignment(.leading)
      Spacer()
      Text(event.occurrenceDate.toString(inFormat: "MMM d"))
        .secondarysText()
      //            Image(systemName: "clock")
      //                .secondaryText()
    }
  }
  
  public var remainingTime: some View {
    HStack(spacing: .small) {
      Spacer()
      
      if timeGap.days > .zero {
        UnitView(value: String(format: "%02d", timeGap.days), unit: "days")
        Spacer()
      }
      
      UnitView(value: String(format: "%02d", timeGap.hours), unit: "hours")
      Spacer()
      UnitView(value: String(format: "%02d", timeGap.minutes), unit: "minutes")
      Spacer()
      UnitView(value: String(format: "%02d", timeGap.seconds), unit: "seconds")
      Spacer()
    }
  }
}

struct UnitsView: View {
  var value: String
  var unit: String
  
  var body: some View {
    VStack(spacing: .zero) {
      ZStack {
        bgCircle
        valueText
      }
      Text(unit).secondarysText()
    }
  }
  
  var valueText: some View {
    Text(value)
      .font(font)
  }
  
  var bgCircle: some View {
    Circle()
      .stroke(style: StrokeStyle())
      .foregroundColor(.secondary)
      .frame(width: .averageTouchSize, height: .averageTouchSize)
  }
  
  var font: Font {
    let font: Font = value.count <= 2 ? .body : .footnote
    return font.monospacedDigit()
  }
}

extension CGFloat {
  static var small: CGFloat { 8 }
  static var medium: CGFloat { 16 }
  static var large: CGFloat { 24 }
  
  static var averageTouchSize: CGFloat { 44 }
  static var imageSize: CGFloat { 72 }
}

extension View {
  func secondarysText() -> some View {
    self
      .font(.footnote)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.leading)
  }
}
