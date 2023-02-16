//
//  NSCustomPersistentContainer.swift
//  Countdown
//
//  Created by Asif on 16/02/23.
//

import Foundation
import UIKit
import CoreData

class NSCustomPersistentContainer: NSPersistentContainer {
  
  override open class func defaultDirectoryURL() -> URL {
    var storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.skydevz.CountDown")
    storeURL = storeURL?.appendingPathComponent("Countdown.sqlite")
    return storeURL!
  }
  
}
