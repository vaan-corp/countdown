//
//  SettingsView.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import EventKit
import SwiftUI
import SwiftyUserInterface
import MessageUI
//import CountdownKit

struct SettingsView: View {
  
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var preferences = Preferences.shared
  //    @ObservedObject var appState = AppState.shared
  //    @ObservedObject var device: Device = Device.shared
  
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
      //            SettingsView()
    }
    .navigationViewStyle(StackNavigationViewStyle())
    //        .stacked(for: device)
  }
  
  var viewStack: some View {
    VStack(spacing: .zero) {
      Group {
        if !preferences.isPaidUser {
          PurchaseCard()
            .sheet(isPresented: $showIAPview, content: { IAPview() })
          //                    .push(to: IAPview(), isPushed: $showIAPview)
            .onTapGesture {
              if ProductStore.shared.products.isEmpty {
                IAPmanager.updateProductsInfo()
                //                                self.showAlert = true
              }
              //                            else {
              self.showIAPview = true
              //                            }
              
            }
        }
//        toggleEventsStyle
      }
      .padding(.top, .small)
      
      ExpandableView(selectionView: displayUnitStack, expandedView: displayUnitPicker)
      
      //            if #available(iOS 14.0, *) {
      //                endDateStack
      //                    .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
      //            } else {
      ExpandableView(selectionView: endDateStack, expandedView: endDatePicker)
      //            }
      
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
      
      //            VStack(spacing: .medium) {
      
      //                Divider()
      //                Toggle(isOn: $preferences.confirmOnDelete, label: {
      //                    ScaledImage(systemName: "exclamationmark.triangle")
      //                        .foregroundColor(.red)
      //                    Text("Confirm on delete")
      //                })
      //            }
      //            .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
      
      
      //            Text("Developed by Imthath").secondaryText().padding(.top)
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
      //            if #available(iOS 14.0, *) {
      //                endDatePicker
      //            } else {
      Text(preferences.endDate.words(in: .short))
        .foregroundColor(.accentColor)
        .layoutPriority(1)
      //            }
      
    }
  }
  
  var endDatePicker: some View {
    DatePicker("", selection: $preferences.endDate, in: Date()..., displayedComponents: .date)
      .labelsHidden()
      .datePickerStyle(WheelDatePickerStyle())
    //            .colorMultiply(Color.primary)
  }
  
  var displayUnitStack: some View {
    HStack {
      ScaledImage(systemName: "hourglass")
        .foregroundColor(.green)
      Text("Display count down in ")
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
      Text(preferences.selectedCalendarsDisplayString)
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
  
  var toggleEventsStyle: some View {
    HStack {
      cardImage
        .foregroundColor(.blue)
      Text("Change events display style")
      Spacer()
    }
    .onTapGesture {
      self.preferences.showEventAsCard.toggle()
      self.presentationMode.wrappedValue.dismiss()
    }
    //        Toggle(isOn: $preferences.showEventAsCard, label: {
    //                            cardImage
    //                                .foregroundColor(.blue)
    //                            Text("Display Events as cards")
    //                        })
    .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
  }
  
  var cardImage: some View {
    preferences.showEventAsCard ?
    ScaledImage(systemName: "rectangle.grid.1x2.fill") :
    ScaledImage(systemName: "list.bullet")
  }
  
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
    Text("""
            We do not save any of your data. We access the Calendar data in this device to show the count down for your events. We also let you add, edit and delete events from this device's Calendar and we have no hold over any of your data. \n \n If you have any questions, feel free to contact us\(MFMailComposeViewController.canSendMail() ? "" : " at imthath.m@icloud.com").
            """)
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
  
  //    var toggleFav: some View {
  //        HStack {
  //            favImage
  //                .foregroundColor(.red)
  //            Text("Indicate favorites in event list")
  ////            toggle(flag: $preferences.showHeartInList, withLabel: "Indicate favorites in event list")
  //            Spacer()
  //        }
  //        .push(to: IAPview(), isPushed: $showIAPview)
  //        .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
  //    .onTapGesture(perform: showIAPifRequired)
  //    }
  //
  //    var favImage: ScaledImage {
  //        if preferences.showHeartInList {
  //            return ScaledImage(systemName: "heart.fill")
  //        }
  //
  //        return ScaledImage(systemName: "heart")
  //    }
  
  //    func showIAPifRequired() {
  //        preferences.showHeartInList.toggle()
  //
  ////        #warning("for testing and demo")
  ////        showIAPview = true
  //        if preferences.showHeartInList,
  //            !preferences.isPaidUser {
  //            appState.showIAPview = true
  //        }
  //    }
}

struct CalendarSelectionView: View {
  
  @ObservedObject var preferences = Preferences.shared
  @ObservedObject var calendar: CDCalendar
  
  @State var showsAlert = false
  var alertMessage = "You must have at least one calendar selected to view events."
  
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
    if calendar.isSelected {
      return Image(systemName: "checkmark.circle.fill")
    }
    
    return Image(systemName: "circle")
  }
  
  var imageColor: Color {
    calendar.isSelected ? calendar.color : Color(.tertiaryLabel)
  }
  
  func changeSelection() {
    if calendar.isSelected && preferences.selectedCalIDs.count <= 1 {
      showsAlert = true
      return
    }
    self.calendar.isSelected.toggle()
    self.preferences.selectedCalIDs = self.preferences.allCalendars
      .filter({ $0.isSelected })
      .map({ $0.id})
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}

