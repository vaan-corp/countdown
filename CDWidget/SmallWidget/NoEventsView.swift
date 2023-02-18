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
  var text: String { kind == "favEvents" ? "No favorite events" : "No events"}
  
  var body: some View {
    VStack(spacing: 20){
      image
        .foregroundColor(.red)
        .imageScale(.large)
      Text(text)
    }
  }
}

struct NoEventsView_Previews: PreviewProvider {
  static var previews: some View {
    NoEventsView(kind: "")
  }
}
