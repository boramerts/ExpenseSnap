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
    private enum Field: Hashable {
        case name, amount, note
    }
    @FocusState private var focusedField: Field?
    
    @ObservedObject var vm: ExpenseViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory: Category = Category(name: "Other", iconName: "tag")
    @State private var note: String = ""
    @State private var date: Date = Date.now
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
                        if focusedField != .note {
                            VStack(alignment: .leading, spacing: 4) {
                                // Type Selector
                                Text("Type")
                                    .font(.headline)
                                Picker("", selection: $isSpending) {
                                    Text("Earning").tag(false)
                                    Text("Spending").tag(true)
                                }
                                .pickerStyle(.segmented)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            
                            // Name Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Name")
                                    .font(.headline)
                                TextField("e.g. Bus Ticket", text: $name)
                                    .focused($focusedField, equals: .name)
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
                                    .focused($focusedField, equals: .amount)
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
                        }
                        
                        // Note Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note (Optional)")
                                .font(.headline)
                            TextField("Add a note…", text: $note)
                                .focused($focusedField, equals: .note)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }
                        
                        // Date Field
                        VStack(alignment: .leading, spacing: 4) {
                            DatePicker(selection: $date, in: ...Date.now, displayedComponents: .date) {
                                Text("Date")
                                    .font(.headline)
                            }
                            .tint(Color.black)
                        }
                    }
                    .animation(.smooth(duration: 0.2), value: focusedField)
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
                            note: note.isEmpty ? nil : note,
                            date: date
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
        .toolbar { // TODO: Add up-down chevrons to change focus between fields.
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button("Done") {
                        focusedField = nil
                    }
                    Spacer()
                    if focusedField != .note {
                        Button {
                            switch focusedField {
                            case .name:
                                focusedField = .amount
                            case .amount:
                                focusedField = .note
                            case .note:
                                focusedField = .name
                            case nil:
                                focusedField = .name
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        Button {
                            switch focusedField {
                            case .name:
                                focusedField = .note
                            case .amount:
                                focusedField = .name
                            case .note:
                                focusedField = .amount
                            case nil:
                                focusedField = .name
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                    }
                }
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
        // Education & Writing
        "pencil", "pencil.line", "text.document", "document", "lock.document", "list.bullet.clipboard",
        "list.clipboard", "heart.text.clipboard", "calendar", "book", "books.vertical", "text.book.closed",
        "bookmark", "graduationcap", "scroll",
        
        // People & Figures
        "person", "person.crop.circle", "figure", "figure.2", "figure.2.arms.open", "figure.walk", "figure.run",
        "figure.dance", "figure.and.child.holdinghands", "figure.2.and.child.holdinghands",
        
        // Office & School Supplies
        "folder", "backpack", "paperclip", "pencil.and.ruler", "ruler", "paintbrush", "paintbrush.pointed",
        "signature", "stethoscope", "printer", "case", "gearshape", "wrench.adjustable", "hammer",
        
        // Technology & Devices
        "display", "pc", "laptopcomputer", "iphone", "apple.terminal", "wifi",
        
        // Home & Furniture
        "sofa", "bed.double", "toilet", "shower", "refrigerator", "tent", "building",
        
        // Security
        "lock", "lock.open", "checkmark.seal", "sos",
        
        // Communication & Media
        "camera", "phone", "video", "envelope",
        
        // Shopping & Finance
        "bag", "cart", "creditcard", "wallet.bifold",
        
        // Travel & Transport
        "airplane", "car", "bus", "tram", "ferry", "bicycle", "moped", "stroller", "fuelpump",
        
        // Nature & Weather
        "sun.max", "moon", "sparkle", "sparkles", "globe.americas", "globe.europe.africa",
        "globe.asia.australia", "globe.central.south.asia",
        
        // Celebrations & Misc
        "party.popper", "balloon.2",
        
        // Symbols & Icons
        "star", "heart", "flag", "tag", "infinity", "repeat", "shuffle",
        
        // Animals
        "hare", "tortoise", "dog", "cat", "lizard", "bird", "fish", "pawprint",
        
        // Clothing
        "tshirt",
        
        // Entertainment
        "theatermasks", "powerplug", "powerplug.portrait"
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
