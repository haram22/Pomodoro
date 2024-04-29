//
//  Tag.swift
//  Pomodoro
//
//  Created by 김현기 on 12/27/23.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import PomodoroDesignSystem
import Realm
import RealmSwift
import UIKit

enum TagCase: String {
    case one, two, three, four, five, six, seven, eight

    var backgroundColor: UIColor {
        switch self {
        case .one:
            return .pomodoro.tagBackground1
        case .two:
            return .pomodoro.tagBackground2
        case .three:
            return .pomodoro.tagBackground3
        case .four:
            return .pomodoro.tagBackground4
        case .five:
            return .pomodoro.tagBackground5
        case .six:
            return .pomodoro.tagBackground6
        case .seven:
            return .pomodoro.tagBackground7
        case .eight:
            return .pomodoro.blackMedium
        }
    }

    var typoColor: UIColor {
        switch self {
        case .one:
            return .pomodoro.tagTypo1
        case .two:
            return .pomodoro.tagTypo2
        case .three:
            return .pomodoro.tagTypo3
        case .four:
            return .pomodoro.tagTypo4
        case .five:
            return .pomodoro.tagTypo5
        case .six:
            return .pomodoro.tagTypo6
        case .seven:
            return .pomodoro.tagTypo7
        case .eight:
            return .lightGray
        }
    }
}

class Tag: Object {
    @Persisted(primaryKey: true) var tagName: String
    @Persisted var colorIndex: String
    @Persisted var position: Int // MARK: Tag Model - Position

    convenience init(tagName: String, colorIndex: String, position: Int) {
        self.init()
        self.tagName = tagName
        self.colorIndex = colorIndex
        self.position = position // MARK: Tag Model - Position
    }

    func setupTagBackgroundColor() -> UIColor {
        TagCase(rawValue: colorIndex)?.backgroundColor ?? UIColor.white
    }

    func setupTagTypoColor() -> UIColor {
        TagCase(rawValue: colorIndex)?.typoColor ?? UIColor.black
    }
}
