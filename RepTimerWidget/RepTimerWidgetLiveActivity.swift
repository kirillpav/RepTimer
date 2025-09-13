//
//  RepTimerWidgetLiveActivity.swift
//  RepTimerWidget
//
//  Created by Kirill Pavlov on 9/13/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RepTimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RepTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RepTimerWidgetAttributes.self) { context in
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

extension RepTimerWidgetAttributes {
    fileprivate static var preview: RepTimerWidgetAttributes {
        RepTimerWidgetAttributes(name: "World")
    }
}

extension RepTimerWidgetAttributes.ContentState {
    fileprivate static var smiley: RepTimerWidgetAttributes.ContentState {
        RepTimerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RepTimerWidgetAttributes.ContentState {
         RepTimerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RepTimerWidgetAttributes.preview) {
   RepTimerWidgetLiveActivity()
} contentStates: {
    RepTimerWidgetAttributes.ContentState.smiley
    RepTimerWidgetAttributes.ContentState.starEyes
}
