//
//  MockData.swift
//  Pomodoro
//
//  Created by 김하람 on 2023/11/27.
//  Copyright © 2023 io.hgu. All rights reserved.
//
import UIKit

// FIXME: - 임시로 사용하는 PomodoroData입니다.
struct PomodoroData {
    var breakTime: Int
    var focusTime: Int
    var tagId: String
    var participateDate: Date
    var success: Bool

    static var dummyData: [PomodoroData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let defaultDate = Date()

        return [
            PomodoroData(
                breakTime: 5,
                focusTime: 25,
                tagId: "공부",
                participateDate: dateFormatter.date(
                    from: "2023-12-30"
                ) ?? defaultDate,
                success: true
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 30,
                tagId: "운동",
                participateDate: dateFormatter.date(
                    from: "2024-01-28"
                ) ?? defaultDate,
                success: false
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 25,
                tagId: "스터디",
                participateDate: dateFormatter.date(
                    from: "2024-01-28"
                ) ?? defaultDate,
                success: true
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 25,
                tagId: "스터디",
                participateDate: dateFormatter.date(
                    from: "2024-01-08"
                ) ?? defaultDate,
                success: false
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 25,
                tagId: "운동",
                participateDate: dateFormatter.date(
                    from: "2024-01-12"
                ) ?? defaultDate,
                success: false
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 25,
                tagId: "공부",
                participateDate: dateFormatter.date(
                    from: "2024-01-09"
                ) ?? defaultDate,
                success: true
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 25,
                tagId: "공부",
                participateDate: dateFormatter.date(
                    from: "2024-01-02"
                ) ?? defaultDate,
                success: true
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 25,
                tagId: "스터디",
                participateDate: dateFormatter.date(
                    from: "2024-01-02"
                ) ?? defaultDate,
                success: true
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 20,
                tagId: "스터디",
                participateDate: dateFormatter.date(from: "2024-01-17") ?? defaultDate,
                success: true
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 20,
                tagId: "스터디",
                participateDate: dateFormatter.date(from: "2024-02-02") ?? defaultDate,
                success: true
            ),
            PomodoroData(
                breakTime: 5,
                focusTime: 20,
                tagId: "스터디",
                participateDate: dateFormatter.date(from: "2024-02-07") ?? defaultDate,
                success: true
            ),
        ]
    }
}

struct TotalPomodoro {
    var totalSessions: Int
    var totalSuccesses: Int
    var totalFailures: Int
    var totalDate: Int

    init(sessions: [PomodoroData]) {
        totalSessions = sessions.count
        totalSuccesses = sessions.filter(\.success).count
        totalFailures = sessions.filter { !$0.success }.count
        totalDate = 1
    }
}
