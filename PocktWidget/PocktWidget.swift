//
//  PocktWidget.swift
//  PocktWidget
//
//  Created by Bora Mert on 25.05.2025.
//

// TODO: Data does not update. Fix it.
// TODO: Create medium and large versions.


import WidgetKit
import SwiftUI
import CoreData

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
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
}

struct PocktWidgetEntryView : View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    var entry: Provider.Entry
    
    @FetchRequest(sortDescriptors: [])
    private var expenses: FetchedResults<Expense>
    private var todayExpenses: [Expense] {
        expenses.filter { expense in
            let ts = Date()
            let calendar = Calendar.current
            return calendar.isDateInToday(ts)
        }
    }
    private var totalExpense: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Today")
                .font(.system(size: 16, weight: .bold))
                .padding(.leading, 7)
            ExpenseBox(expenseValue: totalExpense, renderingMode: widgetRenderingMode)
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
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PocktWidgetEntryView(entry: entry)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .containerBackground(Color("ButtonColor"), for: .widget)
        }
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
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
