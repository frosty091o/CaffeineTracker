//
//  StatsView.swift
//  CaffeineTracker
//
//  Redesigned by ChatGPT for consistent layout & spacing
//

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var manager: CaffeineIntakeManager
    @State private var selectedPeriod = "Week"

    private let periods = ["Week", "Month", "All Time"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Segmented control
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(periods, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 8)

                    // Summary grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        StatCard(
                            title: "Daily Average",
                            value: String(Int(manager.dailyAverage(period: selectedPeriod))),
                            unit: "mg",
                            icon: "chart.bar.fill",
                            tint: .blue
                        )
                        StatCard(
                            title: "Total Drinks",
                            value: String(manager.totalDrinks(period: selectedPeriod)),
                            unit: "drinks",
                            icon: "cup.and.saucer.fill",
                            tint: .green
                        )
                        StatCard(
                            title: "Days Over Limit",
                            value: String(manager.daysOverLimit(period: selectedPeriod)),
                            unit: "days",
                            icon: "exclamationmark.triangle.fill",
                            tint: .red
                        )
                        StatCard(
                            title: "Current Streak",
                            value: String(manager.currentStreak()),
                            unit: "days",
                            icon: "flame.fill",
                            tint: .orange
                        )
                    }

                    // Weekly chart
                    SectionCard(title: "Last 7 Days") {
                        Chart(last7DaysData()) { item in
                            BarMark(
                                x: .value("Day", item.day),
                                y: .value("Caffeine", item.amount)
                            )
                            .foregroundStyle(item.overLimit ? Color.red : Color.blue)
                        }
                        .frame(height: 200)
                        .overlay(
                            GeometryReader { geo in
                                let maxY = max((last7DaysData().map { $0.amount }.max() ?? 0), manager.dailyLimit)
                                let y = maxY == 0 ? geo.size.height : geo.size.height * (1 - CGFloat(manager.dailyLimit / maxY))
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                                }
                                .stroke(Color.orange.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4,3]))
                            }
                        )
                    }

                    // Top beverages
                    SectionCard(title: "Top Beverages") {
                        VStack(spacing: 8) {
                            ForEach(topBeverages(), id: \.name) { bev in
                                HStack(spacing: 12) {
                                    Image(systemName: bev.icon)
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.blue)
                                        .background(.blue.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    Text(bev.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(bev.count) times")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Peak hours
                    SectionCard(title: "Peak Consumption Hours") {
                        HStack(spacing: 5) {
                            ForEach(0..<24) { hour in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(colorForHour(hour))
                                        .frame(width: 10, height: CGFloat(heightForHour(hour)))
                                    Text(hour % 6 == 0 ? "\(hour)" : "")
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                        .frame(height: 10)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                // Global gutter 
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            // centered title like on dashboard
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Statistics")
                        .font(.title2)
                        .bold()
                }
            }
        }
    }

    // MARK: - Data helpers

    func last7DaysData() -> [DayData] {
        var data: [DayData] = []
        let f = DateFormatter(); f.dateFormat = "EEE"
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                let amount = manager.totalCaffeine(for: date)
                data.append(DayData(day: f.string(from: date), amount: amount, overLimit: amount > manager.dailyLimit))
            }
        }
        return data.reversed()
    }

    func topBeverages() -> [(name: String, count: Int, icon: String)] {
        let counts = Dictionary(grouping: manager.entries, by: { $0.beverageType.name })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
        return counts.map { (name: $0.key, count: $0.value, icon: getIcon(for: $0.key)) }
    }

    func getIcon(for beverageName: String) -> String {
        if let entry = manager.entries.first(where: { $0.beverageType.name == beverageName }) {
            return entry.beverageType.category.iconName
        }
        return "cup.and.saucer.fill"
    }

    func heightForHour(_ hour: Int) -> Double {
        let cal = Calendar.current
        let count = manager.entries.filter { cal.component(.hour, from: $0.timestamp) == hour }.count
        return max(6, Double(count * 10))
    }

    func colorForHour(_ hour: Int) -> Color {
        let h = heightForHour(hour)
        if h > 40 { return .red }
        if h > 20 { return .orange }
        if h > 6 { return .blue }
        return .gray.opacity(0.3)
    }
}

// MARK: - Models

struct DayData: Identifiable { let id = UUID(); let day: String; let amount: Double; let overLimit: Bool }

// MARK: - Reusable Cards

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(tint)
                }
                Spacer(minLength: 0)
            }
            // Value + unit
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            // Title
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 118)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}
