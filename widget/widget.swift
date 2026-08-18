import ActivityKit
import SwiftUI
import WidgetKit

struct DeliveryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryAttributes.self) { context in
            HStack {
                Text(context.state.status)
                Spacer()
                Text("\(context.state.eta) min")
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.status)
                }
            } compactLeading: {
                Text("LH")
            } compactTrailing: {
                Text("\(context.state.eta)m")
            } minimal: {
                Text("\(context.state.eta)")
            }
        }
    }
}
