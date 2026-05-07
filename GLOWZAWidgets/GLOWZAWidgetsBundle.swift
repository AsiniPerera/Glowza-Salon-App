//
//  GLOWZAWidgetsBundle.swift
//  GLOWZAWidgets
//
//  Created by COBSCCOMP242P-024 on 2026-05-05.
//

import WidgetKit
import SwiftUI

@main
struct GLOWZAWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GLOWZAWidgets()
        UpcomingBookingsWidget()
        BookAgainWidget()
        GLOWZAWidgetsLiveActivity()
    }
}
