//
//  NSCustomPersistentContainer.swift
//  Countdown
//
//  Created by Asif on 16/02/23.
//

import CoreData
import Foundation
import UIKit

class NSCustomPersistentContainer: NSPersistentContainer {
  override open class func defaultDirectoryURL() -> URL {
    let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Preferences.appGroup)
    guard let url = storeURL else {
      return super.defaultDirectoryURL()
    }
    return url.appendingPathComponent("\(Preferences.appName).sqlite")
  }
}
