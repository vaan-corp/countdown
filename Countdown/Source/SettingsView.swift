//
//  SettingsView.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import EventKit
import MessageUI
import SwiftUI
import WidgetKit

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss
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
        .navigationBarItems(trailing: Button("Done") { dismiss() })
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
      
      displayUnitStack
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.small)
        .padding(EdgeInsets(top: .small, leading: .medium, bottom: .small, trailing: .medium))
       
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
      Image(systemName: "clock")
        .foregroundColor(.orange)
        .imageScale(.large)
        .frame(minWidth: .averageTouchSize)
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
        Image(systemName: "hourglass")
          .foregroundColor(.green)
          .imageScale(.large)
          .frame(minWidth: .averageTouchSize)
        Text("Display countdown in ")
        Spacer()
        Picker("", selection: $preferences.displayComponent) {
          ForEach(0..<CDDefault.components.count) { index in
            Text(CDDefault.components[index].displayString)
          }
        }
      }
      .padding(EdgeInsets(top: .medium, leading: .small, bottom: .medium, trailing: .small))
  }
  
  var calendarStack: some View {
    HStack {
      Image(systemName: "calendar")
        .foregroundColor(.purple)
        .imageScale(.large)
        .frame(minWidth: .averageTouchSize)
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
      Image(systemName: "envelope")
        .foregroundColor(.blue)
        .imageScale(.large)
        .frame(minWidth: .averageTouchSize)
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
      Image(systemName: "lock.shield")
        .foregroundColor(.red)
        .imageScale(.large)
        .frame(minWidth: .averageTouchSize)
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
      Image(systemName: "square.and.pencil")
        .foregroundColor(.yellow)
        .imageScale(.large)
        .frame(minWidth: .averageTouchSize)
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

private struct ExpandableView<SelectionView: View, ExpandedView: View>: View {  
  var selectionView: SelectionView
  var expandedView: ExpandedView
  var backgroundColor: Color
  var canAddPadding: Bool
  
  @State var expandView: Bool
  
  public init(selectionView: SelectionView, expandedView: ExpandedView,
              backgroundColor: Color = Color(.secondarySystemGroupedBackground),
              openExpanded: Bool = false, addPadding: Bool = true) {
    self.selectionView = selectionView
    self.expandedView = expandedView
    self.backgroundColor = backgroundColor
    self._expandView = State(initialValue: openExpanded)
    self.canAddPadding = addPadding
  }
  
  public var body: some View {
    VStack(alignment: .center, spacing: .zero) {
      HStack {
        selectionView
        arrowMark
          .imageScale(.small)
          .foregroundColor(Color(.tertiaryLabel))
      }
      // using medium padding for trailing, small for the arrowMark and small for the HStack
      .padding(EdgeInsets(top: .medium, leading: .small, bottom: .medium, trailing: .medium))
      .contentShape(Rectangle())
      .onTapGesture(perform: toggleView)
      if expandView {
        expandedView
      }
    }
    .background(backgroundColor)
    .cornerRadius(.small)
    .padding(overallPadding)
  }
  
  var overallPadding: EdgeInsets {
    guard canAddPadding else {
      return EdgeInsets(NSDirectionalEdgeInsets.zero)
    }
    
    return EdgeInsets(top: .small, leading: .medium, bottom: .small, trailing: .medium)
  }
  
  var arrowMark: Image {
    if expandView {
      return Image(systemName: "chevron.up")
    }
    
    return Image(systemName: "chevron.down")
  }
  
  func toggleView() {
    withAnimation(.easeInOut(duration: 0.3), {
      self.expandView.toggle()
    })
  }
}


struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
