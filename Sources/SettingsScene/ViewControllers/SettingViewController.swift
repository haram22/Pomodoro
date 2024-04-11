//
//  SettingViewController.swift
//  Pomodoro
//
//  Created by 진세진 on 2023/11/06.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import PomodoroDesignSystem
import SnapKit
import Then
import UIKit

protocol BreakTimeDelegate: AnyObject {
    func updateTableViewRows()
}

protocol PomodoroBreakLongSelectionDelegate: AnyObject {
    func didSelectLongBreak(time: Int)
}

protocol PomodoroBreakShortSelectionDelegate: AnyObject {
    func didSelectShortBreak(time: Int)
}

final class SettingViewController: UIViewController, BreakTimeDelegate {
    let database = DatabaseManager.shared

    private enum SettingOption: CaseIterable {
        case shortBreak, longBreak, completionVibrate, dataReset, timerEffect, serviceReview, OSLicense

        var title: String {
            switch self {
            case .shortBreak:
                return "짧은 휴식 설정하기"
            case .longBreak:
                return "긴 휴식 설정하기"
            case .completionVibrate:
                return "뽀모도로 완료 진동"
            case .dataReset:
                return "데이터 초기화하기"
            case .timerEffect:
                return "타이머 특수효과"
            case .serviceReview:
                return "서비스 평가하러 가기"
            case .OSLicense:
                return "오픈 소스 라이센스"
            }
        }
    }

    private let titleLabel = UILabel().then {
        $0.text = "설정"
        $0.font = UIFont.pomodoroFont.heading3()
    }

    private var shortBreakMinute: Int = 0
    private let longBreakMinute: Int = 0

    private lazy var tableView = UITableView(frame: .zero, style: .plain).then {
        $0.dataSource = self
        $0.delegate = self
        $0.backgroundColor = .pomodoro.background
        $0.contentInset = UIEdgeInsets(top: 0, left: -17, bottom: 0, right: 0)
        $0.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 17)
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "OptionCell")
        $0.isScrollEnabled = false
    }

    private let appIconStackView = UIStackView()

    func setupPomodoroIcon() {
        let logoIcon = UIImageView().then {
            $0.image = UIImage(named: "dashboardIcon")
        }
        let appName = UILabel().then {
            $0.text = "뽀모도로"
            $0.textColor = .pomodoro.primary900
            $0.font = .pomodoroFont.text1(size: 15.27)
        }

        appIconStackView.addArrangedSubview(logoIcon)
        appIconStackView.addArrangedSubview(appName)
        appIconStackView.spacing = 5
        appIconStackView.axis = .horizontal
        appIconStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.equalTo(30)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pomodoro.background

        database.getLocationOfDefaultRealm()
        let options = database.read(Option.self)
        if options.isEmpty {
            database.write(
                Option(
                    shortBreakTime: 5,
                    longBreakTime: 20,
                    isVibrate: false,
                    isTimerEffect: true
                )
            )
        }

        addSubViews()
        setupPomodoroIcon()
        setupConstraints()
    }
}

// MARK: - UITableViewDataSource

extension SettingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        SettingOption.allCases.count
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let realmOption = database.read(Option.self).first

        let cell = UITableViewCell(
            style: .value1,
            reuseIdentifier: "OptionCell"
        )
        cell.backgroundColor = .pomodoro.background
        var config = cell.defaultContentConfiguration()
        let option = SettingOption.allCases[indexPath.row]

        config.text = option.title
        cell.textLabel?.text = option.title
        cell.textLabel?.font = UIFont.pomodoroFont.heading5()
        cell.detailTextLabel?.font = UIFont.pomodoroFont.heading5()
        cell.detailTextLabel?.textColor = .black

        switch SettingOption.allCases[indexPath.row] {
        case .shortBreak:
            cell.accessoryType = .disclosureIndicator
            shortBreakMinute = realmOption?.shortBreakTime ?? -1
            config.secondaryText = "\(shortBreakMinute)min"
            cell.detailTextLabel?.text = config.secondaryText
        case .longBreak:
            cell.accessoryType = .disclosureIndicator
            config.secondaryText = "\(realmOption?.longBreakTime ?? -1)min"
            cell.detailTextLabel?.text = config.secondaryText
        case .completionVibrate:
            let switchView = makeSwitch()
            switchView.setOn(realmOption?.isVibrate ?? false, animated: true)
            switchView.addTarget(self, action: #selector(setupIsVibrate(toggle:)), for: .valueChanged)
            switchView.tag = indexPath.row
            cell.accessoryView = switchView
            cell.selectionStyle = .none
        case .timerEffect:
            let switchView = makeSwitch()
            switchView.setOn(realmOption?.isTimerEffect ?? false, animated: true)
            switchView.addTarget(self, action: #selector(setupIsTimerEffect(toggle:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
        default:
            return cell
        }
        return cell
    }

    private func makeSwitch() -> UISwitch {
        let switchView = UISwitch()
        switchView.onTintColor = .pomodoro.primary900
        switchView.backgroundColor = .pomodoro.blackMedium
        switchView.layer.cornerRadius = 16

        return switchView
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOption = SettingOption.allCases[indexPath.row]
        switch selectedOption {
        case .shortBreak:
            let shortBreakModal = ShortBreakModalViewController()
            shortBreakModal.delegate = self
            presentModal(modalViewController: shortBreakModal)
        case .longBreak:
            let longBreakModal = LongBreakModalViewController()
            longBreakModal.delegate = self
            presentModal(modalViewController: longBreakModal)
        case .completionVibrate:
            tableView.cellForRow(at: indexPath)?.selectionStyle = .none
        case .dataReset:
            showCancellablePopup(
                title: "데이터 초기화 하기",
                body: "데이터를 초기화 하시겠습니까?\n태그, 뽀모도로 기록 등\n모든 데이터와 설정이 초기화됩니다."
            ) { [weak self] in guard let self else { return }
                database.deleteAll()
                database.write(
                    Option(
                        shortBreakTime: 5,
                        longBreakTime: 20,
                        isVibrate: false,
                        isTimerEffect: true
                    )
                )
//                database.write(Tag(tagName: "집중", colorIndex: "one", position: 0))
//                database.write(Tag(tagName: "업무", colorIndex: "two", position: 1))
                updateTableViewRows()
            }
        case .timerEffect:
            tableView.cellForRow(at: indexPath)?.selectionStyle = .none
        case .serviceReview:
            // TODO: body에 넣을 값이 아직 정의가 안되어 있음
            showCancellablePopup(title: "서비스 평가하기", body: "")
        case .OSLicense:
            // TODO: body에 넣을 값이 아직 정의가 안되어 있음
            showCancellablePopup(title: "오픈소스 라이센스", body: "")
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func showCancellablePopup(title: String, body: String, cancelHandler: (() -> Void)? = nil) {
        PomodoroPopupBuilder()
            .add(title: title)
            .add(body: body)
            .add(
                button: .cancellable(
                    cancelButtonTitle: "예",
                    confirmButtonTitle: "아니요",
                    cancelButtonAction: cancelHandler,
                    confirmButtonAction: nil
                )
            )
            .show(on: self)
    }

    private func presentModal(modalViewController: UIViewController) {
        let breakModal = modalViewController
        let nav = UINavigationController(rootViewController: breakModal)

        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        present(nav, animated: true, completion: nil)
    }

    // MARK: Other Delegates

    func updateTableViewRows() {
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
        tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
        tableView.reloadRows(at: [IndexPath(row: 4, section: 0)], with: .automatic)
    }

    // MARK: realm manage

    @objc func setupIsVibrate(toggle: UISwitch) {
        let options = database.read(Option.self).first ?? Option()
        if toggle.isOn {
            database.update(options) { option in
                option.isVibrate = true
            }
        } else {
            database.update(options) { option in
                option.isVibrate = false
            }
        }
    }

    @objc func setupIsTimerEffect(toggle: UISwitch) {
        let options = database.read(Option.self).first ?? Option()
        if toggle.isOn {
            database.update(options) { option in
                option.isTimerEffect = true
            }
        } else {
            database.update(options) { option in
                option.isTimerEffect = false
            }
        }
    }
}

// MARK: UI

extension SettingViewController {
    private func addSubViews() {
        view.addSubview(appIconStackView)
        view.addSubview(titleLabel)
        navigationItem.title = "Options"
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(136)
            make.centerX.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(50)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().inset(0)
            make.bottom.equalToSuperview()
        }
    }
}
