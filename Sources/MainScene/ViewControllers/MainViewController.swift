//
//  MainViewController.swift
//  Pomodoro
//
//  Created by 진세진 on 2023/11/06.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import PomodoroDesignSystem
import SnapKit
import Then
import UIKit

final class MainViewController: UIViewController {
    let pomodoroTimeManager = PomodoroTimeManager.shared
    let database = DatabaseManager.shared

    private var notificationId: String?
    private var longPressTimer: Timer?
    private var longPressTime: Float = 0.0
    var router: PomodoroRouter?

    private var currentPomodoro: Pomodoro?
    private let timeLabel = UILabel().then {
        $0.textAlignment = .center
        $0.font = UIFont.systemFont(ofSize: 60, weight: .heavy)
    }

    private let longPressGuideLabel = UILabel().then {
        $0.text = "길게 클릭해서 타이머를 정지할 수 있어요"
        $0.textAlignment = .center
        $0.textColor = .lightGray
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.isHidden = true
    }

    private let progressBar = UIProgressView().then {
        $0.progressViewStyle = .default
        $0.trackTintColor = .lightGray
        $0.progressTintColor = .systemBlue
        $0.progress = 0.0
        $0.isHidden = true
    }

    private lazy var tagButton = UIButton().then {
        $0.setTitle("Tag", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.titleLabel?.font = UIFont.pomodoroFont.heading1(size: 30)
        $0.addTarget(
            self,
            action: #selector(openTagModal),
            for: .touchUpInside
        )
    }

    private lazy var countButton = UIButton(type: .roundedRect).then {
        $0.setTitle("카운트 시작", for: .normal)
        $0.titleLabel?.font = UIFont.pomodoroFont.heading2(size: 20)
        $0.setTitleColor(.black, for: .normal)
        $0.addTarget(self, action: #selector(startTimer), for: .touchUpInside)
    }

    private lazy var timeButton = UIButton(type: .roundedRect).then {
        $0.setTitle("시간 설정", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.addTarget(self, action: #selector(timeSetting), for: .touchUpInside)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        view.backgroundColor = .pomodoro.background
        addSubviews()
        setupConstraints()
        setupLongPress(isEnable: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateTimeLabel()

        if pomodoroTimeManager.isRestored == true {
            print("ISRESTORED")
            pomodoroTimeManager.setupIsRestored(bool: false)
            // 다시 정보 불러왔을 때 타이머가 진행 중이라면 가장 마지막 뽀모도로 불러오기
            currentPomodoro = database.read(Pomodoro.self).last
            startTimer()
        }
    }

    private func updateTimeLabel() {
        timeLabel.text = String(
            format: "%02d:%02d",
            (pomodoroTimeManager.maxTime - pomodoroTimeManager.currentTime) / 60,
            (pomodoroTimeManager.maxTime - pomodoroTimeManager.currentTime) % 60
        )

        if let id = notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        }
    }
}

// MARK: - Action

extension MainViewController {
    @objc func didEnterBackground() {
        print("max: \(pomodoroTimeManager.maxTime), curr: \(pomodoroTimeManager.currentTime)")
    }

    @objc func didEnterForeground() {
        print("ENTER FOREGROUND")
        print("max: \(pomodoroTimeManager.maxTime), curr: \(pomodoroTimeManager.currentTime)")
        timeLabel.text = String(
            format: "%02d:%02d",
            (pomodoroTimeManager.maxTime - pomodoroTimeManager.currentTime) / 60,
            (pomodoroTimeManager.maxTime - pomodoroTimeManager.currentTime) % 60
        )
    }

    @objc private func openTagModal() {
        let modalViewController = TagModalViewController()
        let navigationController = UINavigationController(rootViewController: modalViewController)
        navigationController.modalPresentationStyle = .automatic
        present(navigationController, animated: true, completion: nil)
    }

    private func setupLongPress(isEnable: Bool) {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )

        longPressGestureRecognizer.isEnabled = isEnable
        longPressGestureRecognizer.allowableMovement = .infinity
        longPressGestureRecognizer.minimumPressDuration = 0.2

        view.addGestureRecognizer(longPressGestureRecognizer)
    }

    @objc private func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        progressBar.isHidden = false

        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(
            timeInterval: 0.02,
            target: self,
            selector: #selector(setProgress),
            userInfo: nil,
            repeats: true
        )
        longPressTimer?.fire()

        if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .ended {
            progressBar.isHidden = true
            longPressTime = 0.0
            progressBar.progress = 0.0
            longPressTimer?.invalidate()
        }
    }

    @objc private func setProgress() {
        longPressTime += 0.01
        progressBar.setProgress(longPressTime, animated: true)

        if longPressTime >= 1 {
            print("LONGPRESS STOP")
            longPressTime = 0.0
            progressBar.progress = 0.0

            longPressTimer?.invalidate()

            database.update(currentPomodoro!) { pomodoro in
                print("[Realm] 뽀모도로 취소")
                pomodoro.phase = 0
                pomodoro.isSuccess = false
            }

            progressBar.isHidden = true

            pomodoroTimeManager.stopTimer {
                setupUIWhenTimerStart(isStopped: true)
                setupLongPress(isEnable: false)
            }

            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            updateTimeLabel()
        }
    }

    @objc private func timeSetting() {
        let timeSettingviewController = TimeSettingViewController(isSelectedTime: false, delegate: self)
        navigationController?.pushViewController(timeSettingviewController, animated: true)
    }

    func setupNotification() {
        notificationId = UUID().uuidString

        let content = UNMutableNotificationContent()
        content.title = "시간 종료!"
        content.body = "시간이 종료되었습니다. 휴식을 취해주세요."

        let request = UNNotificationRequest(
            identifier: notificationId!,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(pomodoroTimeManager.maxTime),
                repeats: false
            )
        )

        UNUserNotificationCenter.current()
            .add(request)
    }

    func setupUIWhenTimerStart(isStopped: Bool) {
        if isStopped == false {
            longPressGuideLabel.isHidden = false
            countButton.isHidden = true
            timeButton.isHidden = true
        } else {
            longPressGuideLabel.isHidden = true
            countButton.isHidden = false
            timeButton.isHidden = false
        }
    }

    @objc private func startTimer() {
        longPressTime = 0.0
        progressBar.progress = 0.0

        setupLongPress(isEnable: true)

        // 강제종료 이후 정보 불러온 상황이 아닐때 (클릭 상황)
        if pomodoroTimeManager.isRestored == false {
            let prevPomodoro = database.read(Pomodoro.self).last

            // 이전 뽀모도로 끝난 경우
            if prevPomodoro?.phase == 0 || prevPomodoro == nil {
                database.createPomodoro(tag: "임시")
            }
            currentPomodoro = database.read(Pomodoro.self).last
        }

        pomodoroTimeManager.startTimer(timerBlock: { timer, currentTime, maxTime in
            self.setupUIWhenTimerStart(isStopped: false)

            let minutes = (maxTime - currentTime) / 60
            let seconds = (maxTime - currentTime) % 60

            if minutes == 0, seconds == 0 {
                timer.invalidate()
                self.setupUIWhenTimerStart(isStopped: true)

                self.database.update(self.currentPomodoro!) { updatedPomodoro in
                    updatedPomodoro.phase += 1
                    if updatedPomodoro.phase == 5 {
                        print("pomodoro 완주!")
                        updatedPomodoro.isSuccess = true
                        updatedPomodoro.phase = 0
                    }
                }

                self.setupLongPress(isEnable: false)

                self.router = PomodoroRouter()
                guard let router = self.router else {
                    return
                }
                router.moveToNextStep(
                    navigationController:
                    self.navigationController ?? UINavigationController()
                )
            }

            self.timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        })

        setupNotification()
    }
}

// MARK: - UI

extension MainViewController {
    private func addSubviews() {
        view.addSubview(countButton)
        view.addSubview(timeLabel)
        view.addSubview(tagButton)
        view.addSubview(timeButton)
        view.addSubview(longPressGuideLabel)
        view.addSubview(progressBar)
    }

    private func setupConstraints() {
        tagButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timeLabel.snp.bottom).offset(20)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.height.equalTo(50)
        }
        longPressGuideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom).offset(-30)
        }
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.67)
        }
        timeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom).offset(-50)
        }
        countButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(timeButton.snp.top).offset(-50)
        }
        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(longPressGuideLabel).offset(-50)
            make.width.equalToSuperview().multipliedBy(0.8)
        }
    }
}

extension MainViewController: TimeSettingViewControllerDelegate {
    func didSelectTime(time: Int) {
        pomodoroTimeManager.setupMaxTime(time: time * 60)
    }
}

extension MainViewController: TagModalViewControllerDelegate {
    func tagSelected(tag _: String) {
        // TODO: 선택된 태그 정보 전달
    }
}
