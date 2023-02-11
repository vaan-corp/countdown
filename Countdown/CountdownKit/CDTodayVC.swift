//
//  CDTodayVC.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import UIKit
import EventKit
import SwiftUI
import NotificationCenter

public protocol TodayControllerProtocol: UIViewController, NCWidgetProviding {
  associatedtype Model : TodayViewProtocol
  var todayModel: Model { get }
  var host: UIViewController { get }
  var hostView: UIView { get }
}

public extension TodayControllerProtocol {
  
  func onViewLoad() {
    CDStore.shared.prepare(forAppGroup: "group.imthath.countdown")
    CDDefault.migrate()
    
    view.addSubview(hostView)
    hostView.alignEdges(with: view, offset: .zero)
    hostView.backgroundColor = .clear
    extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    updateDefaultSize()
  }
  
  // MARK: - Widget provider protocol
  func onWidgetChange(to displayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
    todayModel.checkAndUpdateEvents()
    switch displayMode {
    case .compact:
      preferredContentSize = maxSize
    case .expanded:
      // set intrinsize content size (aka height) of the SwiftUI view
      preferredContentSize = CGSize(width: maxSize.width, height: CGFloat(todayModel.displayEventsCount) * 150)
    @unknown default:
      preconditionFailure("Unexpected value for activeDisplayMode.")
      break
    }
  }
  
  func updateDefaultSize() {
    guard let context = extensionContext else { return }
    withAnimation {
      switch context.widgetActiveDisplayMode {
      case .compact:
        todayModel.isDefaultSize = true
        print("set one event")
      case .expanded:
        todayModel.isDefaultSize = false
        print("set multiple favourite events or four upcoming events")
      @unknown default:
        preconditionFailure("Unexpected value for activeDisplayMode.")
        break
      }
    }
    
  }
}

public extension UIView {
  
  @discardableResult func align(_ type1: NSLayoutConstraint.Attribute,
                                with view: UIView? = nil, on type2: NSLayoutConstraint.Attribute? = nil,
                                offset constant: CGFloat = 0,
                                priority: Float? = nil) -> NSLayoutConstraint? {
    guard let view = view ?? superview else {
      return nil
    }
    
    translatesAutoresizingMaskIntoConstraints = false
    let type2 = type2 ?? type1
    let constraint = NSLayoutConstraint(item: self, attribute: type1,
                                        relatedBy: .equal,
                                        toItem: view, attribute: type2,
                                        multiplier: 1, constant: constant)
    if let priority = priority {
      constraint.priority = UILayoutPriority.init(priority)
    }
    
    constraint.isActive = true
    
    return constraint
  }
  
  func alignEdges(with view: UIView? = nil, offset constant: CGFloat = 0) {
    align(.top, with: view, offset: constant)
    align(.bottom, with: view, offset: -constant)
    align(.leading, with: view, offset: constant)
    align(.trailing, with: view, offset: -constant)
  }
}


