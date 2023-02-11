//
//  Router.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import EventKit
import SwiftUI
//import CountdownKit

class Router: NSObject {
  
  private override init() {
    super.init()
    setUpSearch()
  }
  
  public static let shared = Router()
  
  lazy var navVC = UINavigationController(rootViewController: host)
  lazy var host = UIHostingController(rootView: ContentView())
  let searchController = UISearchController(searchResultsController: nil)
  
  func setUpSearch() {
    searchController.searchBar.backgroundColor = UIColor.systemBackground
    searchController.delegate = self
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
  }
  
  func showSearchBar() {
    host.present(searchController, animated: true)
  }
  
  func showSearchIfRequired() {
    if !Preferences.shared.searchText.isEmpty {
      UIView.performWithoutAnimation {
        host.present(searchController, animated: true)
      }
    }
  }
  
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
  
  func showEventDetail(withID id: String) {
    guard let event = EventStore.store.event(withIdentifier: id) else { return }
    
    showDetail(for: .constant(event))
  }
  
  func showDetail(for event: Binding<EKEvent>) {
    searchController.dismiss(animated: false)
    let newHost = UIHostingController(rootView: EventDetail(event: event))
    newHost.navigationItem.title = event.wrappedValue.title
    navVC.pushViewController(newHost, animated: true)
  }
}

extension Router: UISearchResultsUpdating, UISearchControllerDelegate {
  func updateSearchResults(for searchController: UISearchController) {
    guard let text = searchController.searchBar.text else { return }
    Preferences.shared.searchText = text
    Preferences.shared.updateSearchResults()
  }
}
