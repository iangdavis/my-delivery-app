//
//  deliverywidgetLiveActivity.swift
//  deliverywidget
//
//  Created by user268424 on 8/17/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct deliverywidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct deliverywidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: deliverywidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension deliverywidgetAttributes {
    fileprivate static var preview: deliverywidgetAttributes {
        deliverywidgetAttributes(name: "World")
    }
}

extension deliverywidgetAttributes.ContentState {
    fileprivate static var smiley: deliverywidgetAttributes.ContentState {
        deliverywidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: deliverywidgetAttributes.ContentState {
         deliverywidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: deliverywidgetAttributes.preview) {
   deliverywidgetLiveActivity()
} contentStates: {
    deliverywidgetAttributes.ContentState.smiley
    deliverywidgetAttributes.ContentState.starEyes
}
