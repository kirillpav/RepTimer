//
//  RepTimerWidgetLiveActivity.swift
//  RepTimerWidget
//
//  Created by Kirill Pavlov on 9/13/25.
//

import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<RepTimerWidgetAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            // Timer icon and status
            HStack(spacing: 8) {
                Image(systemName: context.state.isRunning ? "timer" : "pause.circle.fill")
                    .font(.title2)
                    .foregroundColor(context.state.isRunning ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(context.state.isRunning ? "Running" : "Paused")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(context.state.isRunning ? .green : .orange)
                }
            }
            
            Spacer()
            
            // Time display and progress
            VStack(alignment: .trailing, spacing: 6) {
                if context.state.isRunning {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)
                        .foregroundColor(context.state.timeRemaining <= 10 ? .red : .white)
                } else {
                    Text(formatTime(context.state.timeRemaining))
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)
                        .foregroundColor(context.state.timeRemaining <= 10 ? .red : .white)
                }
                
                // Progress bar and info
                VStack(spacing: 3) {
                    ProgressView(value: progressValue(context: context))
                        .tint(context.state.timeRemaining <= 10 ? .red : .green)
                        .frame(width: 100, height: 3)
                    
                    Text("of \(formatTime(context.attributes.totalTime))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func progressValue(context: ActivityViewContext<RepTimerWidgetAttributes>) -> Double {
        guard context.attributes.totalTime > 0 else { return 0 }
        let progress = Double(context.attributes.totalTime - context.state.timeRemaining) / Double(context.attributes.totalTime)
        return max(0, min(1, progress))
    }
}

@available(iOS 16.1, *)
struct RepTimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var timeRemaining: Int // seconds remaining in the timer
        var isRunning: Bool
        var startTime: Date
        var endTime: Date // When the timer should finish
    }

    // Fixed non-changing properties about your activity go here!
    var totalTime: Int // original timer duration in seconds
}

@available(iOS 16.1, *)
struct RepTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RepTimerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isRunning ? "timer" : "pause.circle.fill")
                        .font(.title2)
                        .foregroundColor(context.state.isRunning ? .green : .orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        if context.state.isRunning {
                            Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .fontDesign(.monospaced)
                                .foregroundColor(context.state.timeRemaining <= 10 ? .red : .white)
                        } else {
                            Text(formatTime(context.state.timeRemaining))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .fontDesign(.monospaced)
                                .foregroundColor(context.state.timeRemaining <= 10 ? .red : .white)
                        }
                        ProgressView(value: progressValue(context: context))
                            .tint(context.state.timeRemaining <= 10 ? .red : .green)
                            .frame(width: 50, height: 2)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Rest Timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } compactLeading: {
                Image(systemName: context.state.isRunning ? "timer" : "pause.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            } compactTrailing: {
                if context.state.isRunning {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(context.state.timeRemaining <= 10 ? .red : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(formatTimeCompact(context.state.timeRemaining))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(context.state.timeRemaining <= 10 ? .red : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            } minimal: {
                Image(systemName: context.state.isRunning ? "timer" : "pause.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            }
            .widgetURL(URL(string: "reptimer://timer"))
            .keylineTint(Color.green)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func formatTimeCompact(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else {
            return String(format: ":%02d", remainingSeconds)
        }
    }
    
    private func progressValue(context: ActivityViewContext<RepTimerWidgetAttributes>) -> Double {
        guard context.attributes.totalTime > 0 else { return 0 }
        let progress = Double(context.attributes.totalTime - context.state.timeRemaining) / Double(context.attributes.totalTime)
        return max(0, min(1, progress))
    }
}

extension RepTimerWidgetAttributes {
    fileprivate static var preview: RepTimerWidgetAttributes {
        RepTimerWidgetAttributes(totalTime: 120)
    }
}

extension RepTimerWidgetAttributes.ContentState {
    fileprivate static var running: RepTimerWidgetAttributes.ContentState {
        let now = Date()
        return RepTimerWidgetAttributes.ContentState(
            timeRemaining: 75,
            isRunning: true,
            startTime: now,
            endTime: now.addingTimeInterval(75)
        )
     }
     
     fileprivate static var paused: RepTimerWidgetAttributes.ContentState {
         let now = Date()
         return RepTimerWidgetAttributes.ContentState(
            timeRemaining: 45,
            isRunning: false,
            startTime: now.addingTimeInterval(-30),
            endTime: now.addingTimeInterval(45)
         )
     }
     
     fileprivate static var almostDone: RepTimerWidgetAttributes.ContentState {
         let now = Date()
         return RepTimerWidgetAttributes.ContentState(
            timeRemaining: 8,
            isRunning: true,
            startTime: now.addingTimeInterval(-112),
            endTime: now.addingTimeInterval(8)
         )
     }
}

#Preview("Notification", as: .content, using: RepTimerWidgetAttributes.preview) {
   RepTimerWidgetLiveActivity()
} contentStates: {
    RepTimerWidgetAttributes.ContentState.running
    RepTimerWidgetAttributes.ContentState.paused
    RepTimerWidgetAttributes.ContentState.almostDone
}

#endif

