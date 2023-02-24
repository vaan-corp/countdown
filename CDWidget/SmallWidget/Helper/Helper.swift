//
//  Helper.swift
//  CDWidgetExtension
//
//  Created by Asif on 16/02/23.
//

import EventKit
import Foundation
import SwiftUI

struct Helper {
  var currentTimeStamp: Double { Date.now.timeIntervalSince1970 }

    func getDays(targetTimeStamp: Double) -> Int {
      // first get the difference between target timestamp and current timestamp
      let difference = targetTimeStamp - currentTimeStamp
      // Use quotientAndRemainder method to get quotient as an number of days
      let (quotient, _) = Int(difference).quotientAndRemainder(dividingBy: 24*60*60)
      return quotient
    }
    
    func getDate(targetTimeStamp: Double) -> Date {
      // first get the difference between target timestamp and current timestamp
      let difference = targetTimeStamp - currentTimeStamp
      // Use quotientAndRemainder method to get remainder as remaining hours present in a day
      let (_, remainder) = Int(difference).quotientAndRemainder(dividingBy: 24*60*60)
      // Add remainder to current timestamp to get hours to convert a date
      let hours = currentTimeStamp + Double(remainder)
      return Date(timeIntervalSince1970: hours)
    }
}
