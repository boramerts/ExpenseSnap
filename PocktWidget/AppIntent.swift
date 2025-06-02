//
//  AppIntent.swift
//  PocktWidget
//
//  Created by Bora Mert on 25.05.2025.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Choose which time range to display in the widget." }

    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String

    @Parameter(title: "Time Range", default: TimeRange.today)
    var timeRange: TimeRange

    init(timeRange: TimeRange) {
        self.timeRange = timeRange
    }

    init() {
        self.timeRange = .today
    }
}

enum TimeRange: String, AppEnum {
    case today = "Today"
    case month = "Month"
    case year = "Year"
    case all = "All Time"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Time Range")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "Today"),
        .month: DisplayRepresentation(title: "This Month"),
        .year: DisplayRepresentation(title: "This Year"),
        .all: DisplayRepresentation(title: "All Time")
    ]
}
