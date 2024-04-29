//
//  HapticService.swift
//  Pomodoro
//
//  Created by 김현기 on 4/15/24.
//

import Foundation
import OSLog
import UIKit

enum HapticService {
    static var timer: Timer?

    // warning, error, success
    static func hapticNotification(
        type: UINotificationFeedbackGenerator.FeedbackType,
        duration: TimeInterval = 3,
        interval: TimeInterval = 0.5
    ) {
        stopHapticFeedback()

        let generator = UINotificationFeedbackGenerator()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            generator.notificationOccurred(type)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            stopHapticFeedback()
        }
    }

    static func hapticImpact(
        style: UIImpactFeedbackGenerator.FeedbackStyle,
        duration: TimeInterval = 5,
        interval: TimeInterval = 0.5
    ) {
        stopHapticFeedback()

        let generator = UIImpactFeedbackGenerator(style: style)

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            generator.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            stopHapticFeedback()
        }
    }

    static func stopHapticFeedback() {
        timer?.invalidate()
        timer = nil
    }
}
