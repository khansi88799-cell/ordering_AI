//
//  ordering_AI_AssistantApp.swift
//  ordering_AI_Assistant
//
//  Created by saeed on 02/08/26.
//

import SwiftUI
import CoreData

@main
struct ordering_AI_AssistantApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
