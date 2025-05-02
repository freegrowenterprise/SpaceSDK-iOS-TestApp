//
//  SpaceUWBLiveKitLiveActivity.swift
//  SpaceUWBLiveKit
//
//  Created by min gwan choi on 4/29/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SpaceUWBLiveKitAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SpaceUWBLiveKitLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpaceUWBLiveKitAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("UWB 장치 값 수신 중...")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text("UWB 장치 값 수신 중...")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("UWB 장치 값 수신 중...")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("UWB 장치 값 수신 중...")
                }
            } compactLeading: {
                Text("UWB")
            } compactTrailing: {
                Text("수신 중")
            } minimal: {
                Text("UWB")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SpaceUWBLiveKitAttributes {
    fileprivate static var preview: SpaceUWBLiveKitAttributes {
        SpaceUWBLiveKitAttributes(name: "World")
    }
}

extension SpaceUWBLiveKitAttributes.ContentState {
    fileprivate static var smiley: SpaceUWBLiveKitAttributes.ContentState {
        SpaceUWBLiveKitAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SpaceUWBLiveKitAttributes.ContentState {
         SpaceUWBLiveKitAttributes.ContentState(emoji: "🤩")
     }
}

//#Preview("Notification", as: .content, using: SpaceUWBLiveKitAttributes.preview) {
//   SpaceUWBLiveKitLiveActivity()
//} contentStates: {
//    SpaceUWBLiveKitAttributes.ContentState.smiley
//    SpaceUWBLiveKitAttributes.ContentState.starEyes
//}
