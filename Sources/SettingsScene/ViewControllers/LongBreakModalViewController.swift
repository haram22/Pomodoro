//
//  LongBreakModalViewController.swift
//  Pomodoro
//
//  Created by 김현기 on 1/11/24.
//  Copyright © 2024 io.hgu. All rights reserved.
//

import PomodoroDesignSystem
import UIKit

final class LongBreakModalViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    weak var delegate: BreakTimeDelegate?
    weak var setLongDelegate: PomodoroBreakLongSelectionDelegate?
    private let pomodoroStep = PomodoroStepManger()
    private let label = UILabel().then {
        $0.text = "긴 휴식"
        $0.font = .pomodoroFont.heading3()
    }

    private lazy var confirmButton = PomodoroConfirmButton(title: "확인", didTapHandler: confirmLongBreakInfo)

    private var tempLongBreakTime: Int = 0

    private var minutePicker: UIPickerView = .init()

    func confirmLongBreakInfo() {
        let options = (try? RealmService.read(Option.self).first) ?? Option()
        RealmService.update(options) { option in
            option.longBreakTime = self.tempLongBreakTime + 5
        }
        delegate?.updateTableViewRows()
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pomodoro.background

        view.addSubview(label)
        view.addSubview(minutePicker)
        view.addSubview(confirmButton)
        minutePicker.sizeToFit()
        minutePicker.delegate = self
        minutePicker.dataSource = self

        minutePicker.selectRow(
            ((try? RealmService.read(Option.self).first?.longBreakTime) ?? 0) - 5,
            inComponent: 0,
            animated: true
        )

        setupConstraints()
    }

    private func setupConstraints() {
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(50)
        }

        minutePicker.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.6)
            make.top.equalTo(label.snp.bottom).offset(5)
        }

        confirmButton.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalToSuperview().multipliedBy(0.12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-50)
        }
    }

    func numberOfComponents(in _: UIPickerView) -> Int {
        1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        26
    }

    func pickerView(_: UIPickerView, rowHeightForComponent _: Int) -> CGFloat {
        80
    }

    func pickerView(
        _: UIPickerView,
        viewForRow row: Int,
        forComponent _: Int,
        reusing view: UIView?
    ) -> UIView {
        var label: UILabel
        if let view = view as? UILabel {
            label = view
        } else {
            label = UILabel()
        }

        label.text = "\(row + 5) m"
        label.textAlignment = .center
        label.font = .pomodoroFont.heading3()

        return label
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        tempLongBreakTime = row
        setLongDelegate?.didSelectLongBreak(time: row + 5)
    }
}
