//
//  HomeView.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import EventKit
import Introspect
import SwiftDate
import SwiftUI

class AppState: ObservableObject {
  private init() { }
  
  static let shared = AppState()
  
  @Published var showsSettings: Bool = false
  @Published var showIAPview = false
}

struct HomeView: View {
  @ObservedObject var preferences = Preferences.shared
  @ObservedObject var appState = AppState.shared
  
  @State var isLoading = false
  @State var showsAddEventVC = false
  @State var newEventAdded = false
  @State var searchText = ""
  
  var body: some View {
    NavigationStack {
      mainView
        .sheet(isPresented: $appState.showsSettings, onDismiss: updateEvents, content: settingsView)
        .sheet(isPresented: $showsAddEventVC, onDismiss: dismissedAddEventVC, content: addEventView)
        .multilineTextAlignment(.center)
        .sheet(isPresented: $appState.showIAPview, content: { IAPview() })
        .onAppear(perform: checkPermission)
        .navigationBarTitle("Countdown", displayMode: .inline)
        .navigationBarItems(trailing: trailingStack)
    }
    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    .onChange(of: searchText) {newValue in
      let events = preferences.showFavoritesOnly ? preferences.favoriteEvents : preferences.events
      if !newValue.isEmpty {
        return preferences.displayEvents = events.filter { $0.title.localizedCaseInsensitiveContains(newValue) }
      } else {
        return preferences.displayEvents = events
      }
    }
    .accentColor(.appTintColor)
  }
  
  var trailingStack: some View {
    HStack(spacing: .zero) {
      Menu {
        Button( action: favButtonActions) {
          let image = preferences.showFavoritesOnly ? "heart" : "heart.fill"
          Label( preferences.showFavoritesOnly ? "Show All Events" : "Show Favorites only", systemImage: image)
        }
        
        Button(action: {
          self.appState.showsSettings = true
        }, label: {
          Text("Settings")
          Image(systemName: "gear")
        })
        
        Button(action: {
          self.showsAddEventVC = true
        }, label: {
          Text("Add Event")
          Image(systemName: "plus")
        })
      }
    label: {
      Label("", systemImage: "ellipsis.circle")
      }
    }
  }
  
  func favButtonActions() {
    if self.preferences.isPaidUser {
      preferences.showFavoritesOnly.toggle()
      if preferences.showFavoritesOnly {
        preferences.displayEvents = preferences.favoriteEvents
      } else {
        preferences.displayEvents = preferences.events
      }
    } else {
      if ProductStore.shared.products.isEmpty {
        IAPmanager.updateProductsInfo()
      }
      self.appState.showIAPview = true
    }
  }
  
  func settingsView() -> some View {
    SettingsView()
  }
  
  func dismissedAddEventVC() {
    if newEventAdded {
      preferences.showFavoritesOnly = false
    }
    
    updateEvents()
  }
  
  func updateEvents() {
    "updateEvents".log()
    preferences.updateEvents()
  }
  
  func addEventView() -> some View {
    AddEventVC(eventAdded: $newEventAdded)
  }
  
  var mainView: some View {
    Group {
      if preferences.accessDenied {
        noAccess
      } else if preferences.enabledCalIDs.isEmpty {
        noCalendarEnabled
      } else if preferences.events.isEmpty {
        noEvents
      } else if preferences.showFavoritesOnly && preferences.favoriteEvents.isEmpty {
        noFavoritesView
      } else if preferences.displayEvents.isEmpty {
        noResultsView
      } else {
        eventList
      }
    }.alternateLoader(on: $isLoading)
  }
  
  var noFavoritesView: some View {
    VStack(spacing: .medium) {
      Image(systemName: "heart.fill")
        .foregroundColor(Color.red)
        .font(.system(size: 80.0, weight: .regular))
        .frame(width: 300, height: 300)
      Group {
        Text("You have not added any favorite events yet.")
        Text("Add any event to favorites just by tapping the heart near it.")
      }
      .padding(.horizontal, .averageTouchSize)
    }
    .padding()
    .embedInScrollView()
    .onTapGesture {
      self.preferences.showFavoritesOnly = false
      preferences.displayEvents = preferences.events
    }
  }
  
  var noAccess: some View {
    VStack(spacing: .medium) {
      Image.resizable(withName: "lockedCal")
        .frame(width: 300, height: 300)
      Text("Allow access to the ")
      Text("Calendar").foregroundColor(.accentColor)
      Text("to view the countdown for events")
    }
    .padding()
    .embedInScrollView()
    .onTapGesture(perform: openSettings)
  }
  
  var noCalendarEnabled: some View {
    VStack(spacing: .medium) {
      notepad
      Text("Select some calendars from")
      Text("Settings").foregroundColor(.accentColor)
      Text("to view the countdown for events")
      Spacer()
    }
    .foregroundColor(.secondary)
    .padding()
    .onTapGesture {
      self.appState.showsSettings = true
    }
  }
  
  var noEvents: some View {
    VStack(spacing: .medium) {
      notepad
      Text("There are no events in the enabled calendar(s)")
      
      HStack(spacing: .small) {
        Button("Add Events") {
          self.showsAddEventVC = true
        }
        
        Text("or")
        
        Button("Select more calendars") {
          self.appState.showsSettings = true
        }
      }
      Text("to view the countdown for events")
    }
    .padding()
    .embedInScrollView()
    .onAppear(perform: updateEvents)
  }
  
  var notepad: some View {
    Image.resizable(withName: "notepad")
      .frame(width: 200, height: 200)
      .padding(.top, .imageSize)
  }
  
  @ViewBuilder var eventList: some View {
    if #available(iOS 14.0, *) {
      VStack {
        Spacer()
        resultEvents
        Spacer()
      }
      .embedInScrollView(canShowIndicators: true)
      .background(Color(.systemGroupedBackground))
      .clipped()
    } else {
      introspectedList
    }
  }
  
  var introspectedList: some View {
    resultList
      .introspectTableView { tableView in
        if self.preferences.showEventAsCard {
          tableView.separatorStyle = .none
          tableView.backgroundColor = .systemGroupedBackground
        } else {
          tableView.separatorStyle = .singleLine
          tableView.backgroundColor = .systemBackground
        }
        let footerView = UIView()
        footerView.backgroundColor = .clear
        tableView.tableFooterView = footerView
      }
  }
  var resultList: some View {
    List {
      resultEvents
    }
  }
  
  var resultEvents: some View {
    Section {
      ForEach(preferences.displayEvents, id: \.eventIdentifier) { event in
        EventRow(event: event, searchText: $searchText)
      }
    }
  }
  
  var noResultsView: some View {
    VStack(spacing: .medium) {
      Image.resizable(withName: "magGlass")
        .frame(width: 200, height: 200)
        .padding(.top, .imageSize)
      Text("No events found for \"\(searchText)\"")
        .multilineTextAlignment(.center)
        .padding(.top, .averageTouchSize)
        .foregroundColor(.secondary)
      Spacer()
    }
    .padding()
  }
  
  var canShowSearch: Bool {
    preferences.events.count > 10
  }
  
  func checkPermission() {
    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized:
      EventStore.updateCalendars()
      self.preferences.updateEvents()
    case .denied, .restricted:
      preferences.accessDenied = true
    case .notDetermined:
      self.isLoading = true
      requestPermission()
    @unknown default:
      break
    }
  }
  
  func requestPermission() {
    EventStore.store.requestAccess(to: .event, completion: { (isGranted, _) in
      DispatchQueue.main.async {
        if isGranted {
          self.grantedPermission()
        } else {
          self.preferences.accessDenied = true
          self.isLoading = false
        }
      }
    })
  }
  
  func grantedPermission() {
    DispatchQueue.main.async {
      EventStore.store = EKEventStore()
      EventStore.calendars.forEach { id in
        PersistenceController.shared.saveEnabledCallID(id.calendarIdentifier)
      }
      EventStore.updateCalendars()
      self.updateEvents()
      self.preferences.accessDenied = false
      self.isLoading = false
    }
  }
  
  func openSettings() {
    // TODO: show alert if URL is nil
    if let openSettingsUrl = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(openSettingsUrl, options: [:], completionHandler: nil)
    }
  }
}

extension Int {
  func spellOut(singular: String, plural: String) -> String {
    guard self > 0 else { return "" }
    
    if self == 1 { return singular }
    
    return "\(self) \(plural)"
  }
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
  }
}
