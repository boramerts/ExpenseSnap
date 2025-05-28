//
//  PocktWidget.swift
//  PocktWidget
//
//  Created by Bora Mert on 25.05.2025.
//

// TODO: Create medium and large versions.
// TODO: Improve update logic
// TODO: Work on optimization


import WidgetKit
import SwiftUI
import CoreData

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), totalExpense: 0.0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let totalExpense = await loadTodayTotalExpense()
        return SimpleEntry(date: Date(), configuration: configuration, totalExpense: totalExpense)
    }
    
    private func loadTodayTotalExpense() async -> Double {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        
        let url = AppGroup.pockt.containerURL.appendingPathComponent("ExpenseSnap.sqlite")
        print("Widget store path: \(url.path)")
        print("Exists in widget? \(FileManager.default.fileExists(atPath: url.path))")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let allExpenses = try context.fetch(Expense.fetchRequest())
            
            print("🧩 Widget fetched \(allExpenses.count) TOTAL expenses in database")
            for expense in allExpenses {
                print("Amount: \(expense.amount), Timestamp: \(String(describing: expense.timestamp))")
            }

            let todayExpenses = allExpenses.filter {
                guard let ts = $0.timestamp else { return false }
                return Calendar.current.isDateInToday(ts)
            }

            print("🧩 Widget fetched \(todayExpenses.count) TODAY expenses")
            return todayExpenses.reduce(0) { $0 + $1.amount }
            
        } catch {
            print("❌ Widget fetch failed: \(error)")
            return 0
        }
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let totalExpense = await loadTodayTotalExpense()

        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration, totalExpense: totalExpense)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let totalExpense: Double
}

struct PocktWidgetEntryView : View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Today")
                .font(.system(size: 16, weight: .bold))
                .padding(.leading, 7)
            ExpenseBox(expenseValue: entry.totalExpense, renderingMode: widgetRenderingMode)
            HStack {
                Spacer()
                HStack (spacing: 2) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("Quick Add")
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 5)
                .foregroundStyle(.white)
                Spacer()
            }
            .background(.black.opacity(widgetRenderingMode == .accented ? 0.2 : 1))
            .cornerRadius(10)
        }
    }
}

struct ExpenseBox: View {
    let expenseValue: Double
    let renderingMode: WidgetRenderingMode
    var body: some View {
        HStack {
            Text("$\(expenseValue, specifier: "%.2f")")
                .font(.system(size: 30, weight: .medium))
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
        }
        .padding(.leading, 7)
        .padding(.vertical, 15)
        .background(Color.green.opacity(renderingMode == .accented ? 0 : 0.2))
        .foregroundStyle(Color("TextColor"))
        .cornerRadius(15)
    }
}

@main
struct PocktWidget: Widget {
    let persistenceController = PersistenceController.shared
    let kind: String = "PocktWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider())
        { entry in
            PocktWidgetEntryView(entry: entry)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .containerBackground(Color("ButtonColor"), for: .widget)
        }
        .supportedFamilies([.systemSmall])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    PocktWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, totalExpense: 0.0)
    SimpleEntry(date: .now, configuration: .starEyes, totalExpense: 0.0)
}
