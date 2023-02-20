//
//  NoEventsView.swift
//  CDWidgetExtension
//
//  Created by Asif on 18/02/23.
//

import SwiftUI

struct NoEventsView: View {
  let kind: String
  var image: Image { kind == "favEvents" ? Image(systemName:"heart.fill") : Image("countdown")}
  var favEventsText: String { "Open the app to add favorites." }
  var upcomigEventsText: String { "Please check if your calendars have events and are enabled in the app's settings" }
  var text: String { kind == "favEvents" ? favEventsText : upcomigEventsText}
  
  var body: some View {
    VStack(spacing: 10){
      image
        .foregroundColor(.red)
        .imageScale(.large)
        
      Text(text)
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(.gray)
        .padding([.leading, .trailing], 10)
    }
  }
}

struct NoEventsView_Previews: PreviewProvider {
  static var previews: some View {
    NoEventsView(kind: "")
  }
}
