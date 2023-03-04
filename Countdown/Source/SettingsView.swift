//
//  SettingsView.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import EventKit
import MessageUI
import SwiftUI
import SwiftyUserInterface
import WidgetKit

struct SettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var preferences = Preferences.shared
  
  @State var showsMail = false
  @State var showAlert = false
  @State var showIAPview = false
  
  var alertMessage = "Unable to connect to App Store at the moment. Please try again later."
  
  // TODO: open calendar selection when no calenar is selected or no event is selected
  //    @Binding var openCalendarSelection
  
  var body: some View {
    NavigationView {
      viewStack
        .accentColor(.appTintColor)
        .navigationBarTitle("Settings", displayMode: .inline)
        .navigationBarItems(trailing: DismissButton(title: "Done", presentationMode: presentationMode))
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
  
  var viewStack: some View {
    VStack(spacing: .zero) {
      Group {
        if !preferences.isPaidUser {
          PurchaseCard()
            .sheet(isPresented: $showIAPview, content: { IAPview() })
            .onTapGesture {
              if ProductStore.shared.products.isEmpty {
                IAPmanager.updateProductsInfo()
              }
              self.showIAPview = true
            }
        }
      }
      .padding(.top, .small)
      
      ExpandableView(selectionView: displayUnitStack, expandedView: displayUnitPicker)
      
      ExpandableView(selectionView: endDateStack, expandedView: endDatePicker)
      
      if !preferences.accessDenied && !preferences.allCalendars.isEmpty {
        ExpandableView(selectionView: calendarStack, expandedView: calendarChooser)
      }
      
      ExpandableView(selectionView: privacyPolicyStack, expandedView: privacyPolicyText)
      
      if MFMailComposeViewController.canSendMail() {
        contactUs
      }
      
      writeReview
      
#if DEBUG
      togglePurchase
#endif
    }
    .onAppear(perform: preferences.updateAllCalendars)
    .embedInScrollView()
    .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
  }
  
  var endDateStack: some View {
    HStack {
      ScaledImage(systemName: "clock")
        .foregroundColor(.orange)
      Text("Display events until")
      Spacer()
      Text(preferences.endDate.words(in: .short))
        .foregroundColor(.accentColor)
        .layoutPriority(1)
    }
  }
  
  var endDatePicker: some View {
    DatePicker("", selection: $preferences.endDate, in: Date()..., displayedComponents: .date)
      .labelsHidden()
      .datePickerStyle(WheelDatePickerStyle())
  }
  
  var displayUnitStack: some View {
    HStack {
      ScaledImage(systemName: "hourglass")
        .foregroundColor(.green)
      Text("Display countdown in ")
      Spacer()
      Text(CDDefault.components[preferences.displayComponent].displayString)
        .foregroundColor(.accentColor)
        .layoutPriority(1)
    }
  }
  
  var displayUnitPicker: some View {
    Picker("", selection: $preferences.displayComponent) {
      ForEach(0..<CDDefault.components.count) { index in
        Text(CDDefault.components[index].displayString)
      }
    }
    .labelsHidden()
  }
  
  var calendarStack: some View {
    HStack {
      ScaledImage(systemName: "calendar")
        .foregroundColor(.purple)
      Text("Display events in ")
      Spacer()
      Text(preferences.enabledCalendarsDisplayString)
        .foregroundColor(.accentColor)
        .layoutPriority(1)
    }
  }
  
  var calendarChooser: some View {
    VStack(spacing: .zero) {
      ForEach(preferences.allCalendars, id: \.id) { calendar in
        CalendarSelectionView(calendar: calendar)
      }
    }
  }
  
#if DEBUG
  var togglePurchase: some View {
    VStack {
      Text("Current status - \(preferences.isPaidUser ? "Paid user" : "Free user")")
      
      Button("Toggle purchase") { self.preferences.isPaidUser.toggle() }.buttonStyle(CardButtonStyle())
    }.padding()
  }
#endif
  
  var contactUs: some View {
    HStack {
      ScaledImage(systemName: "envelope").foregroundColor(.blue)
      Text("Contact us")
      Spacer()
    }
    .sheet(isPresented: $showsMail, content: { ComposeMail() })
    .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
    .onTapGesture {
      self.showsMail = true
    }
  }
  
  var privacyPolicyStack: some View {
    HStack {
      ScaledImage(systemName: "lock.shield").foregroundColor(.red)
      Text("Privacy policy")
      Spacer()
    }
  }
  
  var privacyPolicyText: some View {
    Text("We do not save any of your data. We access the Calendar data in this device to show the countdown " +
         "for your events. We also let you add, edit and delete events from this device's Calendar and we have " +
         "no hold over any of your data. \n \n If you have any questions, feel free to contact " +
         "us\(MFMailComposeViewController.canSendMail() ? "" : " at imthath.m@icloud.com").")
    .multilineTextAlignment(.leading)
    .padding()
  }
  
  var writeReview: some View {
    HStack {
      ScaledImage(systemName: "square.and.pencil").foregroundColor(.yellow)
      Text("Write us a review")
      Spacer()
    }
    .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
    .simpleAlert(isPresented: $showAlert, title: "Connection failed", message: alertMessage)
    .onTapGesture {
      self.showAlert = !Router.shared.openAppStore()
    }
  }
}

struct CalendarSelectionView: View {
  @ObservedObject var preferences = Preferences.shared
  @ObservedObject var calendar: CDCalendar
  
  @State var showsAlert = false
  var alertMessage = "You must have at least one calendar enabled to view events."
  
  var body: some View {
    HStack {
      image
        .foregroundColor(imageColor)
        .padding(.small)
      Text(calendar.name)
      Spacer()
    }
    .padding([.leading, .trailing])
    .padding([.top, .bottom], .small)
    .onTapGesture(perform: changeSelection)
    .simpleAlert(isPresented: $showsAlert, message: alertMessage)
  }
  
  var image: some View {
    if PersistenceController.shared.isEnabledCallID(self.calendar.id) {
      return Image(systemName: "checkmark.circle.fill")
    } else {
      return Image(systemName: "circle")
    }
  }
  
  var imageColor: Color {
    PersistenceController.shared.isEnabledCallID(self.calendar.id) ? calendar.color : Color(.tertiaryLabel)
  }
  
  func changeSelection() {
    if calendar.isEnabled && preferences.enabledCalIDs.count <= 1 {
      showsAlert = true
      return
    }
    self.calendar.isEnabled.toggle()
    
    if !PersistenceController.shared.isEnabledCallID(self.calendar.id) {
      PersistenceController.shared.saveEnabledCallID(self.calendar.id)
    } else {
      PersistenceController.shared.removeEnabledCallID(withID: self.calendar.id)
    }
    
    WidgetCenter.shared.reloadAllTimelines()
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
