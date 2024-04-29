//
//  PomodoroTimeManager.swift
//  Pomodoro
//
//  Created by 김현기 on 2/13/24.
//

import Foundation
import UserNotifications

final class PomodoroTimeManager {
    static let shared = PomodoroTimeManager()

    private init() {}

    private var pomodoroTimer: Timer?

    private let userDefaults = UserDefaults.standard
    private let notificationId = UUID().uuidString

    private(set) var currentTime = 0

    func setupCurrentTime(curr: Int) {
        currentTime = curr
    }

    private(set) var maxTime = 0

    func setupMaxTime(time: Int) {
        maxTime = time
    }

    private(set) var isRestored: Bool = false

    func setupIsRestored(bool: Bool) {
        isRestored = bool
    }

    private(set) var isStarted: Bool = false

    func setupIsStarted(bool: Bool) {
        isStarted = bool
    }

    func startTimer(timerBlock: @escaping ((Timer, Int, Int) -> Void)) {
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            timerBlock(timer, self.currentTime + 1, self.maxTime)
            self.currentTime += 1
        }
        pomodoroTimer?.fire()
    }

    func stopTimer(completion: () -> Void) {
        pomodoroTimer?.invalidate()
        currentTime = 0

        let option = try? RealmService.read(Option.self).first
        maxTime = (option?.focusTime ?? 25) * 60

        completion()
    }

    func saveTimerInfo() {
        let lastSavedDate = Date.now
        isRestored = false

        userDefaults.set(lastSavedDate, forKey: "realTime")
        userDefaults.set(currentTime, forKey: "currentTime")
        userDefaults.set(maxTime, forKey: "maxTime")
    }

    func restoreTimerInfo() {
        guard let previousTime = userDefaults.object(forKey: "realTime") as? Date,
              let existCurrentTime = userDefaults.object(forKey: "currentTime") as? Int,
              let existMaxTime = userDefaults.object(forKey: "maxTime") as? Int
        else {
            return
        }

        let realTime = Date.now

        let updatedCurrTime = existCurrentTime + Int(realTime.timeIntervalSince(previousTime))
        maxTime = existMaxTime

        if maxTime > updatedCurrTime {
            isRestored = true
            currentTime = updatedCurrTime
        } else {
            let option = try? RealmService.read(Option.self).first
            maxTime = (option?.focusTime ?? 25) * 60
            currentTime = 0
        }
    }
}
