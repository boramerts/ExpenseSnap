//
//  ExpenseDetail.swift
//  ExpenseSnap
//
//  Created by Bora Mert on 6.05.2025.
//

import SwiftUI

struct ExpenseDetailView: View {
    @ObservedObject var vm: ExpenseViewModel
    @ObservedObject var expense: Expense          // <-- observe the actual object
    let categoryIcon: String
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack(alignment:.center) {
                    Text(expense.name ?? "Unnamed Expense")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
                        .font(.title)
                }
                .padding(.bottom,4)
                HStack(alignment:.center) {
                    Text(Self.dateFormatter.string(from: expense.timestamp ?? Date()))
                        .font(.caption)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: categoryIcon)
                        Text(expense.category ?? "Other")
                    }
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
            
            VStack(alignment: .leading) {
                Text("Note")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 5)
                ScrollView {
                    Text(expense.note ?? "No note provided.")
                }
            }
            .padding()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    let vm = ExpenseViewModel()
    ExpenseDetailView(vm: vm, expense: {
        let sample = Expense(context: vm.container.viewContext)
        sample.name = "Sample Expense"
        sample.amount = 199.99
        sample.category = "Long category Name"
        sample.note = "Eiusmod nisi mollit id anim reprehenderit qui. Duis eiusmod excepteur enim laborum duis laboris laborum minim ullamco consequat do magna duis. Magna occaecat ea ut ut et proident velit consectetur Lorem est. Sit adipisicing duis duis enim ex sunt in laborum exercitation.Ipsum culpa laboris consequat ut laborum. Officia id do in sunt in. Dolor et consectetur excepteur minim minim velit magna. Non Lorem proident fugiat est ullamco excepteur sunt duis proident sint duis nisi irure cupidatat commodo. Minim labore laboris aliqua. Exercitation laboris et consequat ut incididunt elit ex cillum duis ipsum occaecat consectetur enim. Minim ad anim amet labore enim labore enim commodo. Fugiat quis nisi culpa pariatur esse incididunt laborum aliquip dolore dolor dolore exercitation."
        sample.timestamp = Date()
        return sample
    }(), categoryIcon: "tag")
}
