// Wird von scripts/setup-live-activity.sh ans Ende von AppDelegate.swift
// angehaengt (so muss keine neue Datei in Xcode eingebunden werden).
import ActivityKit

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

@objc(LiveRoundPlugin)
public class LiveRoundPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiveRoundPlugin"
    public let jsName = "LiveRound"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "update", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "end", returnType: CAPPluginReturnPromise)
    ]

    private func state(_ call: CAPPluginCall) -> LiveRoundAttributes.ContentState {
        return LiveRoundAttributes.ContentState(
            hole: call.getInt("hole") ?? 1,
            totalHoles: call.getInt("totalHoles") ?? 18,
            par: call.getInt("par") ?? 4,
            strokes: call.getInt("strokes") ?? 0,
            diff: call.getInt("diff") ?? 0
        )
    }

    @objc func start(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else { call.resolve(); return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            call.resolve(["started": false]); return
        }
        let attrs = LiveRoundAttributes(courseName: call.getString("courseName") ?? "Pocket Caddy")
        let content = ActivityContent(state: state(call), staleDate: nil)
        Task {
            for a in Activity<LiveRoundAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
            do {
                _ = try Activity.request(attributes: attrs, content: content, pushType: nil)
                call.resolve(["started": true])
            } catch {
                call.reject("Live Activity konnte nicht gestartet werden: \(error.localizedDescription)")
            }
        }
    }

    @objc func update(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else { call.resolve(); return }
        let content = ActivityContent(state: state(call), staleDate: nil)
        Task {
            for a in Activity<LiveRoundAttributes>.activities {
                await a.update(content)
            }
            call.resolve()
        }
    }

    @objc func end(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else { call.resolve(); return }
        Task {
            for a in Activity<LiveRoundAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
            call.resolve()
        }
    }
}

class LiveRoundViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(LiveRoundPlugin())
    }
}
