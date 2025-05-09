//
//  ExpenseViewModel.swift
//  ExpenseSnap
//
//  Created by Bora Mert on 5.05.2025.
//

import Foundation
import CoreData

class ExpenseViewModel: ObservableObject {
    let container: NSPersistentContainer
    @Published var expenses: [Expense] = []

    init() {
        container = NSPersistentContainer(name: "ExpenseSnap") // Replace with your .xcdatamodeld filename
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed: \(error.localizedDescription)")
            }
        }
        fetchExpenses()
    }

    func fetchExpenses() {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            expenses = try container.viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
        }
    }

    func addExpense(name: String?, amount: Double, category: String, note: String?) {
        let new = Expense(context: container.viewContext)
        new.name = name ?? ""
        new.amount = amount
        new.category = category
        new.note = note
        new.timestamp = Date()

        save()
    }

    func save() {
        do {
            try container.viewContext.save()
            fetchExpenses()
        } catch {
            print("Save error: \(error)")
        }
    }

    func deleteExpense(_ expense: Expense) {
        container.viewContext.delete(expense)
        save()
    }
}
