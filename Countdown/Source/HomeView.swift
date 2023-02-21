//
//  HomeView.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import SwiftUI
import EventKit
import SwiftDate
import SwiftyUserInterface
import Introspect
//import CountdownKit

class AppState: ObservableObject {
  
  private init() { }
  
  static let shared = AppState()
  
  @Published var showsSettings: Bool = false
  @Published var showIAPview = false
}

struct HomeView: View {
  
  @ObservedObject var preferences = Preferences.shared
  @ObservedObject var device: Device = Device.shared
  @ObservedObject var appState = AppState.shared
  
  @State var isLoading = false
  @State var showsAddEventVC = false
  @State var showFavoritesOnly = false
  @State var newEventAdded = false
  @State var search = ""
  
  var searchText: String { preferences.searchText }
  
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
      //        .navigationViewStyle(StackNavigationViewStyle())
      //        .stacked(for: device)
    }
    .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
    .onChange(of: search) {newValue in
      if !newValue.isEmpty {
        return preferences.displayEvents = preferences.events.filter { $0.title.contains(newValue) }
      } else {
        return preferences.displayEvents = preferences.events
      }
    }
    .accentColor(.appTintColor)
  }
  
  var trailingStack: some View {
    HStack(spacing: .zero) {
      Menu {
        Button( action: favButtonActions) {
          Label( showFavoritesOnly ? "Show All Events" : "Show Favorites only", systemImage: "heart.fill")
            .labelStyle(.iconOnly)
            .foregroundColor(.red)
        }
        .foregroundColor(.red)
        
        Button(action: {
          self.appState.showsSettings = true
        }, label: {
          Text("Settings")
          Image(systemName: "gear")
            .imageScale(.large)
            .frame(width: .averageTouchSize, height: .averageTouchSize)
            .foregroundColor(.red)
        })
        
        Button( action: {
          self.showsAddEventVC = true
        }) {
          Label("Add Event",systemImage: "plus")
        }
      }
    label: {
      Label("", systemImage: "ellipsis.circle")
    }
    .tint(Color.accentColor)
    .foregroundColor(.red)
    .accentColor(.appTintColor)
    }
  }
  
  func favButtonActions() {
    if self.preferences.isPaidUser {
      showFavoritesOnly.toggle()
      if showFavoritesOnly {
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
  
  var toggleListButton: some View {
    Button(action: optionC, label: {
      toggleButtonImage()
        .imageScale(.large)
        .frame(width: .averageTouchSize, height: .averageTouchSize)
    }).disabled(preferences.displayEvents.isEmpty)
  }
  
  //    func optionA() {
  //        let temp = self.preferences.searchResults
  //        self.preferences.searchResults = []
  //        self.preferences.showEventAsCard.toggle()
  //        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
  //            self.preferences.searchResults = temp
  //        })
  //    }
  //
  //    func optionB() {
  //        withAnimation(.default, {
  //            self.preferences.showEventAsCard.toggle()
  //        })
  //    }
  //
  func optionC() {
    self.preferences.showEventAsCard.toggle()
  }
  
  //    func optionD() {
  //        withAnimation {
  //            self.preferences.showEventAsCard.toggle()
  //        }
  //    }
  
  func toggleButtonImage() -> Image {
    if preferences.showEventAsCard {
      return Image(systemName: "list.bullet")
    }
    
    return Image(systemName: "rectangle.grid.1x2.fill")
  }
  
  func settingsView() -> some View {
    SettingsView()
    //            .environment(\.layoutDirection, Preferences.layoutDirection)
  }
  
  func dismissedAddEventVC() {
    if newEventAdded {
      showFavoritesOnly = false
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
      } else if preferences.selectedCalIDs.isEmpty {
        noCalendarSelected
      } else if preferences.events.isEmpty {
        noEvents
      } else if preferences.displayEvents.isEmpty {
        noResultsView
      } else if showFavoritesOnly && preferences.favoriteEvents.isEmpty {
        noFavoritesView
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
      self.showFavoritesOnly = false
    }
  }
  
  var noAccess: some View {
    VStack(spacing: .medium) {
      Image.resizable(withName: "lockedCal")
        .frame(width: 300, height: 300)
      Text("Allow access to the ")
      Text("Calendar").foregroundColor(.accentColor)
      Text("to view the count down for events")
    }
    .padding()
    .embedInScrollView()
    .onTapGesture(perform: openSettings)
  }
  
  var noCalendarSelected: some View {
    VStack(spacing: .medium) {
      notepad
      Text("Select some calendars from")
      Text("Settings").foregroundColor(.accentColor)
      Text("to view the count down for events")
    }
    .padding()
    .embedInScrollView()
    .onTapGesture {
      self.appState.showsSettings = true
    }
  }
  
  var noEvents: some View {
    VStack(spacing: .medium) {
      notepad
      Text("There are no events in the selected calendar(s)")
      
      HStack(spacing: .small) {
        Button("Add Events") {
          self.showsAddEventVC = true
        }
        
        Text("or")
        
        Button("Select more calendars") {
          self.appState.showsSettings = true
        }
      }
      Text("to view the count down for events")
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
        LazyVStack {
          resultEvents
        }.embedInScrollView()
        Spacer()
      }
      
      //            if preferences.showEventAsCard {
      //                List(eventsArray, id: \.eventIdentifier) { event in
      //                    EventRow(event: event)
      //                }
      //                    .listStyle(SidebarListStyle())
      //            } else {
      //                resultList
      //                    .listStyle(InsetGroupedListStyle())
      //            }
      
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
        EventRow(event: event)
      }
      //.onDelete(perform: delete)
    }
  }
  
  //    func delete(at offsets: IndexSet) {
  //        preferences.events.remove(atOffsets: offsets)
  //    }
  
  var noResultsView: some View {
    VStack(spacing: .medium) {
      Image.resizable(withName: "magGlass")
        .frame(width: 200, height: 200)
        .padding(.top, .imageSize)
      Text("No reults found for the keyword \"\(searchText)\"")
        .multilineTextAlignment(.center)
        .padding(.top, .averageTouchSize)
      Spacer()
    }
    .padding()
    .embedInScrollView()
  }
  
  var canShowSearch: Bool {
    preferences.events.count > 10
  }
  
  func checkPermission() {
    Router.shared.showSearchIfRequired()
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
    EventStore.store.requestAccess(to: .event, completion: { (isGranted, error) in
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
      EventStore.updateCalendars()
      self.preferences.selectedCalIDs = EventStore.calendars.map { $0.calendarIdentifier }
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
