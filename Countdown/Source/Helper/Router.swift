//
//  Router.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import EventKit
import SwiftUI

class Router: NSObject {
  public static let shared = Router()
  
  @discardableResult
  func openAppStore() -> Bool {
    let webURL = "https://apps.apple.com/app/id1519488760?action=write-review"
    let deepLinkURL = "itms-apps://itunes.apple.com/app/apple-store/id1519488760?mt=8&action=write-review"
    guard let writeReviewURL = URL(string: deepLinkURL) ?? URL(string: webURL) else {
      "Unable top open app store".log()
      return false
    }
    
    UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    return true
  }
}
