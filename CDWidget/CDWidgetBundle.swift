//
//  CDWidgetBundle.swift
//  CDWidget
//
//  Created by Asif on 15/02/23.
//

import WidgetKit
import SwiftUI

@main
struct CDWidgetBundle: WidgetBundle {
  var body: some Widget {
    FavEventsWidget()
    AllEventsWidget()
    if #available(iOSApplicationExtension 16.1, *) {
      CDWidgetLiveActivity()
    }
  }
}
