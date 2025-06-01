//
//  ExpenseSnapApp.swift
//  ExpenseSnap
//
//  Created by Bora Mert on 5.05.2025.
//

import SwiftUI

@main
struct ExpenseSnapApp: App {
  @StateObject private var vm = ExpenseViewModel()
  @State private var showAdd = false

  var body: some Scene {
    WindowGroup {
      ContentView(vm: vm)
        .sheet(isPresented: $showAdd) {
          AddExpenseView(vm: vm)
        }
        .onOpenURL { url in
          // When the widget calls pockt://add, url.host == "add"
          if url.host == "add" {
            showAdd = true
          }
        }
    }
  }
}
