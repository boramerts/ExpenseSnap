//
//  AddExpenseView.swift
//  ExpenseSnap
//
//  Created by Bora Mert on 5.05.2025.
//

import SwiftUI

struct Category: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var iconName: String
}

struct AddExpenseView: View {
    @ObservedObject var vm: ExpenseViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory: Category = Category(name: "Other", iconName: "tag")
    @State private var note: String = ""
    @AppStorage("currencySymbol") private var currencySymbol = "₺"

    @State private var categories: [Category] = [
        Category(name: "Food", iconName: "fork.knife"),
        Category(name: "Transport", iconName: "car"),
        Category(name: "Rent", iconName: "house"),
        Category(name: "Shopping", iconName: "bag"),
        Category(name: "Other", iconName: "tag")
    ]
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var isSpending: Bool = false

    private var isFormValid: Bool {
        Double(amount) != nil
    }

    var body: some View {
        VStack {
            HStack {
                Text("Add Expense")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                Spacer()
            }
            .padding()
            .padding(.horizontal)
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Type Selector
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Type")
                                .font(.headline)
                            Picker("", selection: $isSpending) {
                                Text("Earning").tag(false)
                                Text("Spending").tag(true)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Name Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name")
                                .font(.headline)
                            TextField("e.g. Bus Ticket", text: $name)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }

                        // Amount Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amount (\(currencySymbol))")
                                .font(.headline)
                            TextField("", text: $amount)
                                .keyboardType(.decimalPad)
                                .onChange(of: amount) { newValue in
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    if filtered != newValue {
                                        amount = filtered
                                    }
                                }
                                .padding(12)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isSpending ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSpending ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                                    }
                                )
                        }

                        // Category Menu
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category")
                                .font(.headline)
                            Menu {
                                ForEach(categories) { cat in
                                    Button {
                                        selectedCategory = cat
                                    } label: {
                                        HStack {
                                            Image(systemName: cat.iconName)
                                            Text(cat.name)
                                        }
                                    }
                                }
                                Button("Add New Category…") { showAddCategory = true }
                            } label: {
                                HStack {
                                    Image(systemName: selectedCategory.iconName)
                                    Text(selectedCategory.name)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            }
                        }

                        // Note Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note (Optional)")
                                .font(.headline)
                            TextField("Add a note…", text: $note)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                VStack {
                    Spacer()
                    Button {
                        let value = Double(amount) ?? 0
                        let final = isSpending ? -abs(value) : abs(value)
                        vm.addExpense(
                            name: name,
                            amount: final,
                            category: selectedCategory.name,
                            note: note.isEmpty ? nil : note
                        )
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Save")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .background(isFormValid ? Color("TextColor") : Color.gray)
                        .foregroundColor(Color("ButtonColor"))
                        .cornerRadius(25)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .shadow(radius: 4)
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView(categories: $categories,
                                selectedCategory: $selectedCategory,
                                isPresented: $showAddCategory)
            }
        }
    }
}

#Preview {
    AddExpenseView(vm: ExpenseViewModel())
}

struct AddCategoryView: View {
    @Binding var categories: [Category]
    @Binding var selectedCategory: Category
    @Binding var isPresented: Bool

    @State private var newCategoryName = ""
    @State private var newIconName = "tag"

    let iconOptions = [
        "fork.knife", "bag", "house", "sofa", "oven",
        "car", "truck.box", "airplane",
        "gift", "party.popper", "wallet.bifold",
        "music.note", "tv", "gamecontroller",
        "leaf", "heart", "pawprint",
        "figure.run", "figure.2", "graduationcap",
        "book", "document", "text.document", "building.columns",
        "camera.macro",
        "sun.max", "moon", "globe.europe.africa",
        "curlybraces",
        "pencil"
    ]
    private let iconColumns = [
        GridItem(.adaptive(minimum: 50))
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Name")) {
                    TextField("Name", text: $newCategoryName)
                }
                Section(header: Text("Select Icon")) {
                    ScrollView {
                        LazyVGrid(columns: iconColumns, spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title)
                                    .padding()
                                    .background(newIconName == icon ? Color.blue.opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        newIconName = icon
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let cat = Category(name: newCategoryName, iconName: newIconName)
                        categories.append(cat)
                        selectedCategory = cat
                        isPresented = false
                    }
                    .disabled(newCategoryName.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
