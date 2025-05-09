//
//  ContentView.swift
//  ExpenseSnap
//
//  Created by Bora Mert on 5.05.2025.
//

import SwiftUI
import CoreData

private let categoryIconMap: [String: String] = [
    "Food": "fork.knife",
    "Transport": "car",
    "Rent": "house",
    "Shopping": "bag",
    "Other": "tag"
]

enum TimeFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case month = "This Month"
    case year = "This Year"
    case all = "All Time"
    var id: String { rawValue }
}

struct ContentView: View {
    @StateObject var vm = ExpenseViewModel()
    @State private var showAddExpense = false
    @State private var selectedTimeFilter: TimeFilter = .today
    @State private var selectedCategoryFilter: String = "All"
    @State private var showSettings = false
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    
    @State private var currencySymbolMap: [String: String] = [
        "TRY": "₺",
        "USD": "$",
        "EUR": "€",
        "GBP": "£"
    ]
    
    private var categoriesList: [String] {
        let cats = Set(vm.expenses.map { $0.category ?? "Other" })
        return ["All"] + Array(cats).sorted()
    }
    private var filteredExpenses: [Expense] {
        vm.expenses.filter { expense in
            let ts = expense.timestamp ?? Date()
            let calendar = Calendar.current
            let matchesTime: Bool
            switch selectedTimeFilter {
            case .today:
                matchesTime = calendar.isDateInToday(ts)
            case .month:
                matchesTime = calendar.isDate(ts, equalTo: Date(), toGranularity: .month)
            case .year:
                matchesTime = calendar.isDate(ts, equalTo: Date(), toGranularity: .year)
            case .all:
                matchesTime = true
            }
            let matchesCategory = selectedCategoryFilter == "All" || (expense.category == selectedCategoryFilter)
            return matchesTime && matchesCategory
        }
    }
    
    private var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Helper to generate a row
    @ViewBuilder
    private func expenseRow(for expense: Expense) -> some View {
        NavigationLink(destination: ExpenseDetailView(
            vm: vm,
            expense: expense,
            categoryIcon: categoryIconMap[expense.category ?? "Other"] ?? "tag"
        )) {
            HStack(alignment: .center, spacing: 16) {
                Text(expense.name ?? expense.name! == "" ? "\(expense.category ?? "Other") Expense" : expense.name!)
                    .font(.title2)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                    HStack(spacing: 4) {
                        Image(systemName: categoryIconMap[expense.category ?? "Other"] ?? "tag")
                        Text(expense.category ?? "Other")
                    }
                    .font(.caption)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    List {
                        ForEach(filteredExpenses, id: \.self) { expense in
                            expenseRow(for: expense)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                vm.deleteExpense(vm.expenses[i])
                            }
                        }
                    }
                    .safeAreaPadding(EdgeInsets(top: 0, leading: 0, bottom: 150, trailing: 0))
                    .scrollContentBackground(.hidden)
                }
                
                VStack {
                    Spacer()
                    VStack {
                        HStack {
                            Text("\(currencySymbol)\(totalAmount, specifier: "%.2f") \(selectedTimeFilter.rawValue)")
                                .font(.largeTitle)
                                .bold()
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .padding()
                                .padding(.horizontal, 16)
                                .padding(.bottom, 4)
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(
                                    (totalAmount >= 0 ? Color.green : Color.red)
                                        .opacity(0.2)
                                        .background(.ultraThinMaterial)
                                )
                                .cornerRadius(25)
                                .padding(.horizontal)
                        }
                        
                        Button {
                            showAddExpense = true
                            showSettings = false
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Expense")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color("ButtonColor"))
                            .background(Color("TextColor"))
                            .cornerRadius(25)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .shadow(radius: 4)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Expenses")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack{
                        Menu {
                            Text("Category Filter").font(.headline).disabled(true)
                            Button {
                                selectedCategoryFilter = "All"
                            } label: {
                                Text("All Categories")
                            }
                            ForEach(categoriesList.filter { $0 != "All" }, id: \.self) { cat in
                                Button {
                                    selectedCategoryFilter = cat
                                } label: {
                                    HStack {
                                        Image(systemName: categoryIconMap[cat] ?? "tag")
                                        Text(cat)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "tag")
                                .foregroundStyle(Color("TextColor"))
                        }
                        Menu {
                            Text("Time Filter").font(.headline).disabled(true)
                            ForEach(TimeFilter.allCases) { tf in
                                Button(tf.rawValue) { selectedTimeFilter = tf }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .foregroundStyle(Color("TextColor"))
                        }
                        Button {
                            showSettings = true
                            showAddExpense = false
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(Color("TextColor"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(vm: vm)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(vm: vm)
            }
        }
    }
}


#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
