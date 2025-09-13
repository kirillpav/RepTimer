//
//  ActivityManager.swift
//  RepTimer
//
//  Created by Kirill Pavlov on 9/13/25.
//

import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    @Published var currentActivity: Activity<RepTimerWidgetAttributes>?
    
    private init() {}
    
    func startLiveActivity(totalTime: Int, timeRemaining: Int) {
        // End any existing activity first
        endLiveActivity()
        
        let now = Date()
        let endTime = now.addingTimeInterval(TimeInterval(timeRemaining))
        
        let attributes = RepTimerWidgetAttributes(totalTime: totalTime)
        let contentState = RepTimerWidgetAttributes.ContentState(
            timeRemaining: timeRemaining,
            isRunning: true,
            startTime: now,
            endTime: endTime
        )
        
        do {
            let activity = try Activity<RepTimerWidgetAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            
            currentActivity = activity
            print("✅ Live Activity started successfully")
            
            // Schedule automatic completion
            scheduleActivityCompletion(at: endTime)
        } catch {
            print("❌ Error starting Live Activity: \(error)")
        }
    }
    
    private func scheduleActivityCompletion(at endTime: Date) {
        DispatchQueue.main.asyncAfter(deadline: .now() + endTime.timeIntervalSinceNow) {
            Task {
                await self.completeActivity()
            }
        }
    }
    
    private func completeActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalContentState = RepTimerWidgetAttributes.ContentState(
            timeRemaining: 0,
            isRunning: false,
            startTime: activity.contentState.startTime,
            endTime: activity.contentState.endTime
        )
        
        await activity.end(using: finalContentState, dismissalPolicy: .after(Date().addingTimeInterval(5)))
        currentActivity = nil
        print("✅ Live Activity completed automatically")
    }
    
    func updateLiveActivity(timeRemaining: Int, isRunning: Bool) {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to update")
            return
        }
        
        let now = Date()
        let endTime = isRunning ? now.addingTimeInterval(TimeInterval(timeRemaining)) : activity.contentState.endTime
        
        let contentState = RepTimerWidgetAttributes.ContentState(
            timeRemaining: timeRemaining,
            isRunning: isRunning,
            startTime: activity.contentState.startTime, // Keep original start time
            endTime: endTime
        )
        
        Task {
            await activity.update(using: contentState)
        }
    }
    
    func endLiveActivity() {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to end")
            return
        }
        
        let finalContentState = RepTimerWidgetAttributes.ContentState(
            timeRemaining: 0,
            isRunning: false,
            startTime: activity.contentState.startTime,
            endTime: activity.contentState.endTime
        )
        
        Task {
            await activity.end(using: finalContentState, dismissalPolicy: .immediate)
        }
        
        currentActivity = nil
        print("✅ Live Activity ended")
    }
    
    func pauseLiveActivity(timeRemaining: Int) {
        updateLiveActivity(timeRemaining: timeRemaining, isRunning: false)
    }
    
    func resumeLiveActivity(timeRemaining: Int) {
        updateLiveActivity(timeRemaining: timeRemaining, isRunning: true)
    }
    
    // Check if Live Activities are supported and enabled
    var isLiveActivitySupported: Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
}

// Extension to handle RepTimerWidgetAttributes for the main app
struct RepTimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: Int
        var isRunning: Bool
        var startTime: Date
        var endTime: Date // When the timer should finish
    }
    
    var totalTime: Int
}

#else
// Fallback for when ActivityKit is not available
class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    private init() {}
    
    func startLiveActivity(totalTime: Int, timeRemaining: Int) {
        print("⚠️ ActivityKit not available - Live Activities not supported")
    }
    
    func updateLiveActivity(timeRemaining: Int, isRunning: Bool) {
        // No-op
    }
    
    func endLiveActivity() {
        // No-op
    }
    
    func pauseLiveActivity(timeRemaining: Int) {
        // No-op
    }
    
    func resumeLiveActivity(timeRemaining: Int) {
        // No-op
    }
    
    var isLiveActivitySupported: Bool {
        return false
    }
}
#endif
