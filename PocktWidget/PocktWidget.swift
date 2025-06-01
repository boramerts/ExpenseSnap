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
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            totalToday: 0.0,
            totalMonth: 0.0,
            totalYear: 0.0,
            totalAll: 0.0
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // For snapshot, just fetch all ranges once
        let today    = await loadTotalExpense(range: "today")
        let month    = await loadTotalExpense(range: "month")
        let year     = await loadTotalExpense(range: "year")
        let allTime  = await loadTotalExpense(range: "all")
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            totalToday: today,
            totalMonth: month,
            totalYear: year,
            totalAll: allTime
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Fetch each range once, then reuse for each timeline entry
        let today    = await loadTotalExpense(range: "today")
        let month    = await loadTotalExpense(range: "month")
        let year     = await loadTotalExpense(range: "year")
        let allTime  = await loadTotalExpense(range: "all")
        
        for hourOffset in 0..<5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(
                date: entryDate,
                configuration: configuration,
                totalToday: today,
                totalMonth: month,
                totalYear: year,
                totalAll: allTime
            )
            entries.append(entry)
        }
        
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    /// Fetches and returns the sum of expenses for the requested range.
    /// - Parameter range: "today", "month", "year", or "all"
    /// - Returns: The total matching the range
    private func loadTotalExpense(range: String) async -> Double {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        
        do {
            let allExpenses = try context.fetch(fetchRequest)
            let calendar = Calendar.current
            let now = Date()
            
            switch range.lowercased() {
            case "today":
                let startOfDay = calendar.startOfDay(for: now)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                return allExpenses
                    .filter { expense in
                        guard let ts = expense.timestamp else { return false }
                        return ts >= startOfDay && ts < endOfDay
                    }
                    .reduce(0) { $0 + $1.amount }
                
            case "month":
                let components = calendar.dateComponents([.year, .month], from: now)
                let startOfMonth = calendar.date(from: components)!
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                return allExpenses
                    .filter { expense in
                        guard let ts = expense.timestamp else { return false }
                        return ts >= startOfMonth && ts < endOfMonth
                    }
                    .reduce(0) { $0 + $1.amount }
                
            case "year":
                let components = calendar.dateComponents([.year], from: now)
                let startOfYear = calendar.date(from: components)!
                let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear)!
                return allExpenses
                    .filter { expense in
                        guard let ts = expense.timestamp else { return false }
                        return ts >= startOfYear && ts < endOfYear
                    }
                    .reduce(0) { $0 + $1.amount }
                
            case "all":
                return allExpenses.reduce(0) { $0 + $1.amount }
                
            default:
                return 0
            }
        } catch {
            print("❌ Widget fetch failed: \(error)")
            return 0
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let totalToday: Double
    let totalMonth: Double
    let totalYear: Double
    let totalAll: Double
}

struct PocktWidgetEntryView : View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    @Environment(\.widgetFamily) var family
    
    var entry: Provider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallBody
        case .systemMedium:
            mediumBody
        case .systemLarge:
            largeBody
        case .systemExtraLarge:
            Text("")
        case .accessoryCircular:
            circularBody
        case .accessoryRectangular:
            rectangularBody
            // To show monthly instead of daily:
            // rectangularMonthBody
            // To show yearly:
            // rectangularYearBody
            // To show all-time:
            // rectangularAllBody
        case .accessoryInline:
            inlineBody
            // To show monthly:
            // inlineMonthBody
            // To show yearly:
            // inlineYearBody
            // To show all-time:
            // inlineAllBody
        @unknown default:
            smallBody
        }
    }
    
    /// Small widget shows only today's total
    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Today")
                .font(.system(size: 16, weight: .bold))
                .padding(.leading, 7)
            ExpenseBox(expenseValue: entry.totalToday, renderingMode: widgetRenderingMode)
                .frame(height: 50)
            HStack {
                Spacer()
                Link(destination: URL(string: "pockt://add")!) {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Quick Add")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 5)
                    .foregroundStyle(.white)
                }
                Spacer()
            }
            .background(.black.opacity(widgetRenderingMode == .accented ? 0.2 : 1))
            .cornerRadius(10)
        }
    }
    
    /// Medium widget shows today's and this month's totals
    private var mediumBody: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                VStack (alignment: .leading){
                    Text("Today")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.leading, 8)
                    ExpenseBox(expenseValue: entry.totalToday, renderingMode: widgetRenderingMode)
                        .frame(height: 55)
                }
                VStack (alignment: .leading){
                    Text("Month")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.leading, 8)
                    ExpenseBox(expenseValue: entry.totalMonth, renderingMode: widgetRenderingMode)
                        .frame(height: 55)
                }
            }
            HStack {
                Spacer()
                Link(destination: URL(string: "pockt://add")!) {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Quick Add")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 5)
                    .foregroundStyle(.white)
                }
                Spacer()
            }
            .background(.black.opacity(widgetRenderingMode == .accented ? 0.2 : 1))
            .cornerRadius(10)
        }
    }
    
    /// Large widget shows today, month, year, and all-time totals
    private var largeBody: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Today")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.leading, 8)
                Spacer()
                ExpenseBox(expenseValue: entry.totalToday, renderingMode: widgetRenderingMode)
                    .frame(width: 200, height: 60)
            }
            
            HStack {
                Text("Month")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.leading, 8)
                Spacer()
                ExpenseBox(expenseValue: entry.totalMonth, renderingMode: widgetRenderingMode)
                    .frame(width: 200, height: 60)
            }
            
            HStack {
                Text("Year")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.leading, 8)
                Spacer()
                ExpenseBox(expenseValue: entry.totalYear, renderingMode: widgetRenderingMode)
                    .frame(width: 200, height: 60)
            }
            
            HStack {
                Text("All Time")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.leading, 8)
                Spacer()
                ExpenseBox(expenseValue: entry.totalAll, renderingMode: widgetRenderingMode)
                    .frame(width: 200, height: 60)
            }
            
            HStack {
                Spacer()
                Link(destination: URL(string: "pockt://add")!) {
                    HStack {
                        Spacer()
                        HStack(spacing: 2) {
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
                    .frame(width: 200, height: 40)
                    .background(.black.opacity(widgetRenderingMode == .accented ? 0.2 : 1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var circularBody: some View {
        // Compute short-form string with "k" if needed
        let total = entry.totalToday
        let displayText: String
        if total >= 1_000 {
            let thousands = Int(total / 1_000)
            displayText = "\(thousands)k"
        } else {
            displayText = String(format: "%.0f", total)
        }

        return VStack {
            Image(systemName: "wallet.bifold")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25)
            Text("$\(displayText)")
                .font(.system(size: 16, weight: .regular))
        }
    }
    
    private var inlineBody: some View {
        HStack {
            Image(systemName: "wallet.bifold")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("$\(entry.totalToday, specifier: "%.2f")")
        }
    }

    /// Inline body showing this month's total
    private var inlineMonthBody: some View {
        HStack {
            Image(systemName: "calendar")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("$\(entry.totalMonth, specifier: "%.2f")")
        }
    }

    /// Inline body showing this year's total
    private var inlineYearBody: some View {
        HStack {
            Image(systemName: "calendar.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("$\(entry.totalYear, specifier: "%.2f")")
        }
    }

    /// Inline body showing all-time total
    private var inlineAllBody: some View {
        HStack {
            Image(systemName: "infinity")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("$\(entry.totalAll, specifier: "%.2f")")
        }
    }

    private var rectangularBody: some View {
        VStack(alignment: .leading) {
            Text("Today")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.primary.opacity(0.5))
            Text("$\(entry.totalToday, specifier: "%.2f")")
                .font(.system(size: 20, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    /// Rectangular body showing this month's total
    private var rectangularMonthBody: some View {
        VStack(alignment: .leading) {
            Text("Month")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.primary.opacity(0.5))
            Text("$\(entry.totalMonth, specifier: "%.2f")")
                .font(.system(size: 20, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    /// Rectangular body showing this year's total
    private var rectangularYearBody: some View {
        VStack(alignment: .leading) {
            Text("Year")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.primary.opacity(0.5))
            Text("$\(entry.totalYear, specifier: "%.2f")")
                .font(.system(size: 20, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    /// Rectangular body showing all-time total
    private var rectangularAllBody: some View {
        VStack(alignment: .leading) {
            Text("All Time")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.primary.opacity(0.5))
            Text("$\(entry.totalAll, specifier: "%.2f")")
                .font(.system(size: 20, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
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
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
        }
        .padding(.leading, 12)
        .padding(.vertical, 12)
        .background(expenseValue > 0 ? Color.green.opacity(renderingMode == .accented ? 0 : 0.2) : Color.red.opacity(renderingMode == .accented ? 0 : 0.2))
        .foregroundStyle(Color("TextColor"))
        .cornerRadius(12)
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    PocktWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: .smiley,
        totalToday: 120000.34,
        totalMonth: 56000.78,
        totalYear: 123.45,
        totalAll: 987.65
    )
    SimpleEntry(
        date: .now,
        configuration: .starEyes,
        totalToday: -10.0,
        totalMonth: -100.0,
        totalYear: 0.0,
        totalAll: 30000.0
    )
}
