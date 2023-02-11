//
//  EventKitUIWrappers.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import SwiftUI
import EventKitUI
import MessageUI
//import CountdownKit

struct AddEventVC: UIViewControllerRepresentable {
  
  typealias UIViewControllerType = EKEventEditViewController
  
  @Environment(\.presentationMode) var presentationMode
  @Binding var eventAdded: Bool
  
  func makeUIViewController(context: Context) -> EKEventEditViewController {
    
    let controller = EKEventEditViewController()
    controller.event = EKEvent(eventStore: EventStore.store)
    controller.eventStore = EventStore.store
    controller.editViewDelegate = context.coordinator
    return controller
  }
  
  func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {
    // do nothing
  }
  
  func makeCoordinator() -> AddEventVC.Coordinator {
    return Coordinator(presentationMode: presentationMode, eventAdded: $eventAdded)
  }
  
  class Coordinator : NSObject, UINavigationControllerDelegate, EKEventEditViewDelegate {
    var presentationMode: Binding<PresentationMode>
    var isEventAdded: Binding<Bool>
    
    init(presentationMode: Binding<PresentationMode>, eventAdded: Binding<Bool>) {
      self.presentationMode = presentationMode
      self.isEventAdded = eventAdded
    }
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
      switch action {
      case .canceled:
        "Canceled".log()
        presentationMode.wrappedValue.dismiss()
      case .saved:
        do {
          try controller.eventStore.save(controller.event!, span: .thisEvent, commit: true)
          "saved event".log()
          self.isEventAdded.wrappedValue = true
        }
        catch {
          "Problem saving event".log()
        }
        presentationMode.wrappedValue.dismiss()
      case .deleted:
        print("Deleted")
        presentationMode.wrappedValue.dismiss()
      @unknown default:
        print("I shouldn't be here")
        presentationMode.wrappedValue.dismiss()
      }
    }
  }
}

struct EditEventVC: UIViewControllerRepresentable {
  
  typealias UIViewControllerType = EKEventEditViewController
  
  @Environment(\.presentationMode) var presentationMode
  
  @Binding var event: EKEvent
  @Binding var isDeleted: Bool
  
  func makeUIViewController(context: Context) -> EKEventEditViewController {
    let controller = EKEventEditViewController()
    controller.event = event
    controller.eventStore = EventStore.store
    controller.editViewDelegate = context.coordinator
    return controller
  }
  
  func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {
    // do nothing
  }
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(presentationMode: presentationMode,
                       event: $event, isDeleted: $isDeleted)
  }
  
  class Coordinator : NSObject, UINavigationControllerDelegate, EKEventEditViewDelegate {
    var presentationMode: Binding<PresentationMode>
    var event: Binding<EKEvent>
    var isDeleted: Binding<Bool>
    
    init(presentationMode: Binding<PresentationMode>,
         event: Binding<EKEvent>, isDeleted: Binding<Bool>) {
      self.presentationMode = presentationMode
      self.event = event
      self.isDeleted = isDeleted
    }
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
      switch action {
      case .canceled:
        "Canceled".log()
        presentationMode.wrappedValue.dismiss()
      case .saved:
        do {
          try controller.eventStore.save(controller.event!, span: .thisEvent, commit: true)
          "saved event".log()
        }
        catch {
          "Problem saving event".log()
        }
        event.wrappedValue = controller.event!
        presentationMode.wrappedValue.dismiss()
      case .deleted:
        print("Deleted")
        isDeleted.wrappedValue = true
        presentationMode.wrappedValue.dismiss()
      @unknown default:
        print("I shouldn't be here")
        presentationMode.wrappedValue.dismiss()
      }
    }
  }
  
}

struct EventVC: UIViewControllerRepresentable {
  typealias UIViewControllerType = EKEventViewController
  
  @Binding var event: EKEvent
  
  func makeUIViewController(context: Context) -> EKEventViewController {
    
    let controller = EKEventViewController()
    controller.event = event
    controller.allowsEditing = true
    return controller
  }
  
  func updateUIViewController(_ uiViewController: EKEventViewController, context: Context) {
    // do nothing
  }
}

//struct CalendarChooser: UIViewControllerRepresentable {
//
//
//    typealias UIViewControllerType = EKCalendarChooser
//
//    var store = EKEventStore()
//    @Binding var selectedCalendars: Set<EKCalendar>
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    func makeUIViewController(context: Context) -> EKCalendarChooser {
//        let calChooser = EKCalendarChooser(selectionStyle: .multiple, displayStyle: .allCalendars,
//                                           entityType: .event, eventStore: store)
//        calChooser.delegate = context.coordinator
//        calChooser.selectedCalendars = selectedCalendars
//        return calChooser
//    }
//
//    func updateUIViewController(_ uiViewController: EKCalendarChooser, context: Context) {
//        selectedCalendars = context.coordinator.selectedCalendars
//    }
//
//    class Coordinator: NSObject, EKCalendarChooserDelegate {
//
//        var selectedCalendars = Set<EKCalendar>()
//
//        func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
//            selectedCalendars = calendarChooser.selectedCalendars
//        }
//    }
//
//}

public struct ComposeMail: UIViewControllerRepresentable {
  
  public typealias UIViewControllerType = MFMailComposeViewController
  
  @Environment(\.presentationMode) var presentationMode
  
  public func makeUIViewController(context: Context) -> MFMailComposeViewController {
    let mail = MFMailComposeViewController()
    mail.setToRecipients(["imthath.m@icloud.com"])
    mail.setSubject("Count Down app feedback - ")
    mail.mailComposeDelegate = context.coordinator
    return mail
  }
  
  public func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
    // do nothing
  }
  
  public func makeCoordinator() -> Coordinator {
    Coordinator(presentationMode: presentationMode)
  }
  
  public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    var presentationMode: Binding<PresentationMode>
    
    init(presentationMode: Binding<PresentationMode>) {
      self.presentationMode = presentationMode
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
      presentationMode.wrappedValue.dismiss()
    }
  }
}

