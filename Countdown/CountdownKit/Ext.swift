//
//  Ext.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import Combine
import EventKit
import SwiftDate
import SwiftUI

public extension Array where Element: EKEvent {
  var distinct: [Element] {
    var set = Set<String>()
    
    return self.filter({
      guard $0.occurrenceDate > Date() else {
        return false
      }
      
      let (isSuccess, _) = set.insert($0.eventIdentifier)
      return isSuccess
    })
  }
}

public extension TimeInterval {
  func relativeTime(in locale: Locale = .current) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(fromTimeInterval: self)
  }
}

public extension Locale {
  static var preferred: Locale {
    guard let preferredIdentifier = Locale.preferredLanguages.first else {
      return Locale.current
    }
    return Locale(identifier: preferredIdentifier)
  }
}

public extension Date {
  func relativeTime(in locale: Locale = .current) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    formatter.locale = Locale.preferred
    return formatter.localizedString(for: self, relativeTo: Date())
  }
  
  func words(in style: DateFormatter.Style = .long) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = style
    return formatter.string(from: self)
  }
  
  func toString(inFormat format: String = "MMM dd, yyyy") -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: self)
  }
  
  var timeGap: TimeGap {
    var result = TimeGap()
    var timeInterval = timeIntervalSinceNow
    
    result.days = Int64(timeInterval / (24 * 60 * 60))
    timeInterval = timeInterval.truncatingRemainder(dividingBy: (24 * 60 * 60))
    
    result.hours = Int(timeInterval / (60 * 60))
    timeInterval = timeInterval.truncatingRemainder(dividingBy: (60 * 60))
    
    result.minutes = Int(timeInterval / 60)
    timeInterval = timeInterval.truncatingRemainder(dividingBy: 60)
    
    result.seconds = Int(timeInterval)
    
    return result
  }
}

public extension Timer {
  /// publishes time value every second
  static var secondlyPublisher: Publishers.Autoconnect<Timer.TimerPublisher> {
    return Timer.publish(
      every: 1,
      on: .main,
      in: .common
    ).autoconnect()
  }
}

public extension String {
  func log(file: String = #file,
           functionName: String = #function,
           lineNumber: Int = #line) {
    print("\(URL(fileURLWithPath: file).lastPathComponent)-\(functionName):\(lineNumber)  \(self)")
  }
}

public extension EKEvent {
  func difference(in component: Calendar.Component) -> String {
    guard let diff = DateInRegion(occurrenceDate).difference(in: component, from: DateInRegion()),
          diff > 1 else {
      return occurrenceDate.relativeTime()
    }
    
    return "in " + "\(diff) \(component.suffixPlural)"
  }
  
  var attendeeString: String {
    guard let array = attendees else { return "" }
    var result = ""
    
    for attendee in array {
      guard let name = attendee.name else { continue }
      result.append("\(name), ")
    }
    
//    result.removeLast(2)
    return result
  }
  var locationString: String { location ?? "" }
  
  var alarmsString: String {
    guard let array = alarms else { return "" }
    var result = ""
    
    for alarm in array {
      var relativeTime = alarm.relativeOffset.relativeTime()
      if let date = alarm.absoluteDate {
        result.append(date.toString(inFormat: "MMM dd, yyyy, HH:mm, "))
      } else if !relativeTime.isEmpty {
        if alarm.relativeOffset < 0 {
          relativeTime = relativeTime.replacingOccurrences(of: "ago", with: "before")
          //                } else {
          //                    relativeTime.replacingOccurrences(of: "", with: <#T##StringProtocol#>)
        }
        result.append("\(relativeTime), ")
      }
    }
    
//    result.removeLast(2)
    return result
  }
  var urlString: String { url?.absoluteString ?? "" }
  
  var color: Color { Color(UIColor(cgColor: calendar.cgColor)) }
}

public extension EKCalendar {
  var color: Color {
    Color(UIColor(cgColor: cgColor))
  }
}

public extension Calendar.Component {
  var nowString: String {
    switch self {
      //        case .minute:
      //            return "Minutes"
      //        case .hour:
      //            return "Hours"
    case .weekOfYear:
      return "This week"
    case .month:
      return "This month"
    case .year:
      return "This year"
    default:
      return "Today"
    }
  }
  
  //    var suffixSingular: String {
  //        switch self {
  //            //        case .minute:
  //            //            return "Minutes"
  //            //        case .hour:
  //        //            return "Hours"
  //        case .weekOfYear:
  //            return "a week"
  //        case .month:
  //            return "a month"
  //        case .year:
  //            return "an year"
  //        default:
  //            return "a day"
  //        }
  //    }
  
  var suffixPlural: String {
    switch self {
      //        case .minute:
      //            return "Minutes"
      //        case .hour:
      //            return "Hours"
    case .weekOfYear:
      return "weeks"
    case .month:
      return "months"
    case .year:
      return "years"
    default:
      return "days"
    }
  }
  
  var displayString: String {
    switch self {
    case .minute:
      return "Minutes"
    case .hour:
      return "Hours"
    case .weekOfYear:
      return "Weeks"
    case .month:
      return "Months"
    case .year:
      return "Years"
    default:
      return "Days"
    }
  }
}

public extension Array {
  subscript(safe index: Int) -> Element? {
    guard index >= 0, index < endIndex else {
      return nil
    }
    
    return self[index]
  }
}
