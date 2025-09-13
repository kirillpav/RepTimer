//
//  ContentView.swift
//  RepTimer
//
//  Created by Kirill Pavlov on 9/8/25.
//

import SwiftUI
import AVFoundation
import AudioToolbox
import UIKit
#if canImport(ActivityKit)
import ActivityKit
#endif

struct AnimatedDigit: View {
    let digit: Int
    let color: Color
    @State private var animationOffset: CGFloat = 0
    @State private var displayedDigit: Int = 0
    
    var body: some View {
        ZStack {
            // Current digit
            Text("\(displayedDigit)")
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .offset(y: animationOffset)
                .clipped()
            
            // Next digit (for animation)
            Text("\(digit)")
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .offset(y: animationOffset + 100)
                .clipped()
        }
        .frame(width: 45, height: 100)
        .clipped()
        .onChange(of: digit) { oldValue, newValue in
            if oldValue != newValue {
                animateDigitChange()
            }
        }
        .onAppear {
            displayedDigit = digit
        }
    }
    
    private func animateDigitChange() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationOffset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            displayedDigit = digit
            animationOffset = 0
        }
    }
}

struct ContentView: View {
    @State private var timeRemaining: Int = 120 // Will be updated from UserDefaults
    @State private var defaultRestTime: Int = 120
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isOnboardingComplete: Bool = false
    @State private var showingSettings: Bool = false
    @State private var displayedMinutes1: Int = 0 // First digit of minutes
    @State private var displayedMinutes2: Int = 2 // Second digit of minutes  
    @State private var displayedSeconds1: Int = 0 // First digit of seconds
    @State private var displayedSeconds2: Int = 0 // Second digit of seconds
    @Environment(\.colorScheme) private var colorScheme
    
    // Live Activity Manager
    @StateObject private var activityManager = ActivityManager.shared
    
    // Adaptive colors based on appearance mode
    private var adaptiveForeground: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var adaptiveBackground: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var adaptiveInverseForeground: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var adaptiveInverseBackground: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        Group {
            if isOnboardingComplete && !showingSettings {
                timerView
                    .onAppear {
                        checkOnboardingStatus()
                        setupAudioSession()
                        updateDisplayedDigits()
                    }
            } else {
                OnboardingView(
                    isOnboardingComplete: showingSettings ? .constant(true) : $isOnboardingComplete,
                    showingSettings: $showingSettings
                )
                .onAppear {
                    checkOnboardingStatus()
                    setupAudioSession()
                }
            }
        }
        .onChange(of: showingSettings) { _, newValue in
            if !newValue && isOnboardingComplete {
                // Reload default time when returning from settings
                loadDefaultRestTime()
            }
        }
    }
    
    private var timerView: some View {
        VStack(spacing: 50) {
            // Settings button at the top
            HStack {
                Spacer()
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(adaptiveForeground)
                }
                .disabled(isRunning)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
            
            // Individual Animated Digits Timer Display
            HStack(spacing: 8) {
                // Minutes
                AnimatedDigit(
                    digit: displayedMinutes1,
                    color: timeRemaining <= 10 ? .red : .primary
                )
                AnimatedDigit(
                    digit: displayedMinutes2,
                    color: timeRemaining <= 10 ? .red : .primary
                )
                
                // Colon separator
                Text(":")
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                
                // Seconds
                AnimatedDigit(
                    digit: displayedSeconds1,
                    color: timeRemaining <= 10 ? .red : .primary
                )
                AnimatedDigit(
                    digit: displayedSeconds2,
                    color: timeRemaining <= 10 ? .red : .primary
                )
            }
            .onChange(of: timeRemaining) { oldValue, newValue in
                updateDisplayedDigits()
            }
            
            Spacer()
            
            // Control Buttons
            HStack(spacing: 30) {
                // -15 seconds button
                Button(action: {
                    adjustTime(-15)
                }) {
                    Text("-15s")
                        .font(.title2)
                        .foregroundColor(adaptiveInverseForeground)
                        .frame(width: 80, height: 50)
                        .background(adaptiveInverseBackground)
                        .cornerRadius(10)
                }
                
                // Start/Stop button
                Button(action: {
                    toggleTimer()
                }) {
                    Text(isRunning ? "Stop" : "Start")
                        .font(.title2)
                        .foregroundColor(isRunning ? .secondary : adaptiveInverseForeground)
                        .frame(width: 100, height: 50)
                        .background(isRunning ? .secondary : adaptiveInverseBackground)
                        .cornerRadius(10)
                }
                
                // +15 seconds button
                Button(action: {
                    adjustTime(15)
                }) {
                    Text("+15s")
                        .font(.title2)
                        .foregroundColor(adaptiveInverseForeground)
                        .frame(width: 80, height: 50)
                        .background(adaptiveInverseBackground)
                        .cornerRadius(10)
                }
            }
            .padding(.bottom, 50)
            
            // Reset to default button
            Button(action: {
                resetToDefault()
            }) {
                Text("Reset to \(formatTime(defaultRestTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .disabled(isRunning)
        }
        .onDisappear {
            // Don't stop timer when app goes to background - let live activity continue
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Sync timer state when app comes to foreground
            syncTimerWithLiveActivity()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func adjustTime(_ seconds: Int) {
        let newTime = timeRemaining + seconds
        timeRemaining = max(0, newTime) // Don't allow negative time
        updateDisplayedDigits()
        
        // Update Live Activity if running
        if #available(iOS 16.1, *), isRunning {
            activityManager.updateLiveActivity(timeRemaining: timeRemaining, isRunning: true)
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        guard timeRemaining > 0 else { return }
        
        isRunning = true
        
        // Start Live Activity if supported
        if #available(iOS 16.1, *), activityManager.isLiveActivitySupported {
            activityManager.startLiveActivity(totalTime: defaultRestTime, timeRemaining: timeRemaining)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Update Live Activity
                if #available(iOS 16.1, *) {
                    activityManager.updateLiveActivity(timeRemaining: timeRemaining, isRunning: true)
                }
            } else {
                stopTimer()
                playChime()
                timeRemaining = defaultRestTime
            }
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // End Live Activity
        if #available(iOS 16.1, *) {
            activityManager.endLiveActivity()
        }
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    private func playChime() {
        // Use system sound for chime
        AudioServicesPlaySystemSound(1016) // This is a built-in chime sound
    }
    
    private func checkOnboardingStatus() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if isOnboardingComplete {
            loadDefaultRestTime()
        }
    }
    
    private func loadDefaultRestTime() {
        let savedTime = UserDefaults.standard.integer(forKey: "defaultRestTime")
        if savedTime > 0 {
            defaultRestTime = savedTime
            timeRemaining = savedTime
            updateDisplayedDigits()
        }
    }
    
    private func resetToDefault() {
        timeRemaining = defaultRestTime
        updateDisplayedDigits()
    }
    
    private func updateDisplayedDigits() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        
        displayedMinutes1 = minutes / 10
        displayedMinutes2 = minutes % 10
        displayedSeconds1 = seconds / 10
        displayedSeconds2 = seconds % 10
    }
    
    private func syncTimerWithLiveActivity() {
        if #available(iOS 16.1, *), let activity = activityManager.currentActivity {
            let now = Date()
            
            // Check if timer should have finished
            if now >= activity.contentState.endTime && activity.contentState.isRunning {
                // Timer finished while app was in background
                stopTimer()
                playChime()
                timeRemaining = defaultRestTime
                updateDisplayedDigits()
                return
            }
            
            // Update timer based on live activity state
            if activity.contentState.isRunning {
                let remainingTime = max(0, Int(activity.contentState.endTime.timeIntervalSince(now)))
                timeRemaining = remainingTime
                updateDisplayedDigits()
                
                if timeRemaining > 0 && !isRunning {
                    // Restart the app timer to sync with live activity
                    isRunning = true
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        let currentRemaining = max(0, Int(activity.contentState.endTime.timeIntervalSince(Date())))
                        timeRemaining = currentRemaining
                        
                        if timeRemaining <= 0 {
                            stopTimer()
                            playChime()
                            timeRemaining = defaultRestTime
                        }
                    }
                }
            }
        }
    }
}

struct OnboardingView: View {
    @State private var selectedMinutes = 2 // Default to 2 minutes
    @State private var selectedSeconds = 0 // Default to 0 seconds
    @Binding var isOnboardingComplete: Bool
    @Binding var showingSettings: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // Adaptive colors based on appearance mode
    private var adaptiveForeground: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var adaptiveInverseForeground: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var adaptiveInverseBackground: Color {
        colorScheme == .dark ? .white : .black
    }
    
    let minutes = Array(0...10) // 0 to 10 minutes
    let seconds = Array(stride(from: 0, through: 55, by: 5)) // 0, 5, 10, 15, ..., 55
    
    var body: some View {
        VStack(spacing: 40) {
            // Top bar with back button (when in settings mode)
            HStack {
                if showingSettings {
                    Button(action: {
                        showingSettings = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.title3)
                        .foregroundColor(adaptiveForeground)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            VStack(spacing: 20) {
                Text(showingSettings ? "Change Default Rest Time" : "How much time do you rest between sets?")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Native iOS Timer-style picker
            HStack(spacing: 0) {
                // Minutes Picker
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(minutes, id: \.self) { minute in
                        Text("\(minute)")
                            .font(.system(size: 24, weight: .regular, design: .default))
                            .tag(minute)
                    }
                }
#if os(iOS)
                .pickerStyle(WheelPickerStyle())
#else
                .pickerStyle(MenuPickerStyle())
#endif
                .frame(width: 80)
                .clipped()
                
                Text("min")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
                    .padding(.trailing, 20)
                
                // Seconds Picker
                Picker("Seconds", selection: $selectedSeconds) {
                    ForEach(seconds, id: \.self) { second in
                        Text("\(second)")
                            .font(.system(size: 24, weight: .regular, design: .default))
                            .tag(second)
                    }
                }
#if os(iOS)
                .pickerStyle(WheelPickerStyle())
#else
                .pickerStyle(MenuPickerStyle())
#endif
                .frame(width: 80)
                .clipped()
                
                Text("sec")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
            }
            .frame(height: 180)
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: {
                saveRestTime()
                withAnimation {
                    if showingSettings {
                        showingSettings = false
                    } else {
                        isOnboardingComplete = true
                    }
                }
            }) {
                Text(showingSettings ? "Save Changes" : "Get Started")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(adaptiveInverseForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(adaptiveInverseBackground)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .onAppear {
            if showingSettings {
                loadCurrentDefaults()
            }
        }
    }
    
    private func saveRestTime() {
        let totalSeconds = (selectedMinutes * 60) + selectedSeconds
        UserDefaults.standard.set(totalSeconds, forKey: "defaultRestTime")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    private func loadCurrentDefaults() {
        let savedTime = UserDefaults.standard.integer(forKey: "defaultRestTime")
        if savedTime > 0 {
            selectedMinutes = savedTime / 60
            selectedSeconds = savedTime % 60
        }
    }
}

#Preview {
    ContentView()
}

#Preview("Onboarding") {
    OnboardingView(isOnboardingComplete: .constant(false), showingSettings: .constant(false))
}
