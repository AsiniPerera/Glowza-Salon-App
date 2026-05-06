//
//  GLOWZAWidgetsLiveActivity.swift
//  GLOWZAWidgets
//
//  Created by COBSCCOMP242P-024 on 2026-05-05.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GLOWZAWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GLOWZAWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GLOWZAWidgetsAttributes.self) { context in
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

extension GLOWZAWidgetsAttributes {
    fileprivate static var preview: GLOWZAWidgetsAttributes {
        GLOWZAWidgetsAttributes(name: "World")
    }
}

extension GLOWZAWidgetsAttributes.ContentState {
    fileprivate static var smiley: GLOWZAWidgetsAttributes.ContentState {
        GLOWZAWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GLOWZAWidgetsAttributes.ContentState {
         GLOWZAWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GLOWZAWidgetsAttributes.preview) {
   GLOWZAWidgetsLiveActivity()
} contentStates: {
    GLOWZAWidgetsAttributes.ContentState.smiley
    GLOWZAWidgetsAttributes.ContentState.starEyes
}
