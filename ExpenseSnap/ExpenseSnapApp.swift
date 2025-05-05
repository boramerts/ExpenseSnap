//
//  ExpenseSnapApp.swift
//  ExpenseSnap
//
//  Created by Bora Mert on 5.05.2025.
//

import SwiftUI

@main
struct ExpenseSnapApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
