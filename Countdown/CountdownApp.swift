//
//  CountdownApp.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import SwiftUI

@main
struct CountdownApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
