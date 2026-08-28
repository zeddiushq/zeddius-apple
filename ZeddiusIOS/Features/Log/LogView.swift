import SwiftUI

/// Weight/Sleep/Food merged under one tab so the bottom bar doesn't run
/// past 4 items. Each screen keeps its own NavigationStack/toolbar/model
/// untouched — this just swaps which one is on screen.
///
/// Deliberately NOT `TabView(.page)`: a paged TabView is backed by a
/// horizontally-scrolling container, and SwiftUI lays out a large
/// navigationTitle's leading padding against that container's full
/// multi-page width rather than the single visible page's width — every
/// page but the first ends up with its title hugging the left edge,
/// misaligned with the content below it. A plain conditional avoids the
/// bug entirely since only one screen is ever actually mounted. Trade-off:
/// switching segments refetches rather than resuming instantly — fine at
/// this data size.
struct LogView: View {
    @AppStorage("logSelectedSegment") private var selection = LogSegment.food

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selection) {
                ForEach(LogSegment.allCases) { segment in
                    Text(segment.label).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .frame(minWidth: 250, maxWidth: 280)
            .padding()

            switch selection {
            case .weight: WeightListView()
            case .sleep: SleepListView()
            case .food: FoodEntryListView()
            }
        }
    }
}

private enum LogSegment: String, CaseIterable, Identifiable {
    case weight, sleep, food

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weight: "Weight"
        case .sleep: "Sleep"
        case .food: "Food"
        }
    }
}

#Preview {
    LogView()
        .environment(APIClient())
}
