//
//  SettingsView.swift
//  ExpenseSnap
//
//  Created by Bora Mert on 6.05.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: ExpenseViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("Currency")) {
                        Picker("Currency", selection: $currencySymbol) {
                            Text("Turkish Lira (₺)").tag("₺")
                            Text("US Dollar ($)").tag("$")
                            Text("Euro (€)").tag("€")
                            Text("British Pound (£)").tag("£")
                        }
                        .pickerStyle(.menu)
                    }
                    Section(header: Text("Data")) {
                        Button("Delete All Expenses") {
                            showDeleteConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
                Text("ExpenseSnap | by Bora Mert 2025")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
                Button("Delete All", role: .destructive) {
                    for expense in vm.expenses {
                        vm.deleteExpense(expense)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove all expenses. This action cannot be undone.")
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(vm: ExpenseViewModel())
}
