//
//  Helper.swift
//  CDWidgetExtension
//
//  Created by Asif on 16/02/23.
//

import Foundation
import EventKit
import SwiftUI

struct Helper {
  var currentTimeStamp : Double { Date.now.timeIntervalSince1970 }

    func getDays(targetTimeStamp: Double) -> Int {
      // first get the difference between target timestamp and current timestamp
      let difference = targetTimeStamp - currentTimeStamp
      // Use quotientAndRemainder method to get quotient as an number of days
      let (q,_) = Int(difference).quotientAndRemainder(dividingBy: 24*60*60)
      return q
    }
    
    func getDate(targetTimeStamp: Double) -> Date {
      // first get the difference between target timestamp and current timestamp
      let difference = targetTimeStamp - currentTimeStamp
      // Use quotientAndRemainder method to get remainder as remaining hours present in a day
      let (_,r) = Int(difference).quotientAndRemainder(dividingBy: 24*60*60)
      // Add remainder to current timestamp to get hours to convert a date
      let hours = currentTimeStamp + Double(r)
      return Date(timeIntervalSince1970: hours)
    }
}
