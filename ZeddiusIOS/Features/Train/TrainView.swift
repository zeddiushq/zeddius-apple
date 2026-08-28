import SwiftUI

/// Lift/Run merged under one tab, same pattern as LogView — a plain
/// conditional swap, not `TabView(.page)` (see LogView's doc comment for
/// why: paged TabView breaks large-title layout on non-first pages).
struct TrainView: View {
    @AppStorage("trainSelectedSegment") private var selection = TrainSegment.lift

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selection) {
                ForEach(TrainSegment.allCases) { segment in
                    Text(segment.label).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .frame(minWidth: 170, maxWidth: 200)
            .padding()

            switch selection {
            case .lift: WorkoutListView()
            case .run: RunListView()
            }
        }
    }
}

private enum TrainSegment: String, CaseIterable, Identifiable {
    case lift, run

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lift: "Lift"
        case .run: "Run"
        }
    }
}

#Preview {
    TrainView()
        .environment(APIClient())
}
