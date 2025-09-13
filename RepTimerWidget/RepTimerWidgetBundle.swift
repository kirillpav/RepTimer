//
//  RepTimerWidgetBundle.swift
//  RepTimerWidget
//
//  Created by Kirill Pavlov on 9/13/25.
//

import WidgetKit
import SwiftUI

@main
struct RepTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RepTimerWidget()
        RepTimerWidgetControl()
        RepTimerWidgetLiveActivity()
    }
}
