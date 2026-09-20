import ActivityKit
import WidgetKit
import SwiftUI

struct LiveRoundAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var hole: Int
        var totalHoles: Int
        var par: Int
        var strokes: Int
        var diff: Int
    }
    var courseName: String
}

private let lime = Color(red: 0.639, green: 0.902, blue: 0.208)
private let good = Color(red: 0.369, green: 0.871, blue: 0.561)
private let bad = Color(red: 1.0, green: 0.361, blue: 0.361)

private func scoreText(_ diff: Int) -> String {
    return diff > 0 ? "+\(diff)" : "\(diff)"
}

private func scoreColor(_ diff: Int) -> Color {
    return diff < 0 ? good : (diff > 0 ? bad : .white)
}

private struct LockScreenView: View {
    let attrs: LiveRoundAttributes
    let state: LiveRoundAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(attrs.courseName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                Text("Loch \(state.hole) von \(state.totalHoles)")
                    .font(.headline)
                    .foregroundColor(lime)
                Text("Par \(state.par)  \u{00B7}  \(state.strokes) Schl\u{00E4}ge")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            Spacer()
            Text(scoreText(state.diff))
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundColor(scoreColor(state.diff))
        }
        .padding(16)
        .activityBackgroundTint(Color(red: 0.063, green: 0.071, blue: 0.09))
        .activitySystemActionForegroundColor(lime)
    }
}

struct PocketCaddyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveRoundAttributes.self) { context in
            LockScreenView(attrs: context.attributes, state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Loch \(context.state.hole)")
                        .font(.headline)
                        .foregroundColor(lime)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(scoreText(context.state.diff))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(scoreColor(context.state.diff))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.courseName)
                        .font(.caption)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Par \(context.state.par)  \u{00B7}  \(context.state.strokes) Schl\u{00E4}ge  \u{00B7}  \(context.state.hole)/\(context.state.totalHoles)")
                        .font(.subheadline)
                }
            } compactLeading: {
                Text("L\(context.state.hole)")
                    .foregroundColor(lime)
            } compactTrailing: {
                Text(scoreText(context.state.diff))
                    .foregroundColor(scoreColor(context.state.diff))
            } minimal: {
                Text(scoreText(context.state.diff))
                    .foregroundColor(scoreColor(context.state.diff))
            }
            .keylineTint(lime)
        }
    }
}
