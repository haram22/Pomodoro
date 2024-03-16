//
//  BreakTimerViewController.swift
//  Pomodoro
//
//  Created by 김하람 on 2/19/24.
//

import SnapKit
import Then
import UIKit

final class BreakTimerViewController: UIViewController {
    private var timer: Timer?
    private var notificationId: String?
    private var currentTime = 0
    private var maxTime = 2 * 60
    private var longPressTimer: Timer?
    private var longPressTime: Float = 0.0
    private var timerHeightConstraint: Constraint?
    var router = PomodoroRouter()
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

    private lazy var breakLabel = UILabel().then {
        $0.text = "휴식시간"
        $0.textColor = .black
        $0.font = UIFont.systemFont(ofSize: 60, weight: .heavy)
    }

    private lazy var timerBackground = UIView().then {
        $0.backgroundColor = .pomodoro.primary900
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubviews()
        setupConstraints()
        startTimer()
        startAnimationTimer()
        longPressSetting(isEnable: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateTimeLabel()
        // FIXME: Remove startTimer() after implementing time setup
    }

    private func updateTimeLabel() {
        let minutes = (maxTime - currentTime) / 60
        let seconds = (maxTime - currentTime) % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)

        if let id = notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        }
    }
}

// MARK: - Action

extension BreakTimerViewController {
    @objc private func openTagModal() {
        let modalViewController = TagModalViewController()
        modalViewController.modalPresentationStyle = .fullScreen
        present(modalViewController, animated: true, completion: nil)
    }

    private func longPressSetting(isEnable: Bool) {
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
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.02,
                                              target: self,
                                              selector: #selector(setProgress),
                                              userInfo: nil,
                                              repeats: true)
        longPressTimer?.fire()

        if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .ended {
            progressBar.isHidden = true
            longPressTime = 0.0
            progressBar.progress = 0.0

            longPressTimer?.invalidate()
        }
    }

    @objc private func setProgress() {
        longPressTime += 0.02
        progressBar.setProgress(longPressTime, animated: true)

        if longPressTime >= 1 {
            longPressTime = 0.0
            progressBar.progress = 0.0
            longPressTimer?.invalidate()

            progressBar.isHidden = true
            stopTimer()
        }
    }

    @objc private func stopTimer() {
        timer?.invalidate()
        currentTime = 0
        maxTime = 0
        updateTimeLabel()
        router.moveToNextStep(navigationController: navigationController ?? UINavigationController())
        longPressGuideLabel.isHidden = true
    }

    @objc private func timeSetting() {
        let timeSettingviewController = TimeSettingViewController(isSelectedTime: false, delegate: self)
        navigationController?.pushViewController(timeSettingviewController, animated: true)
    }

    @objc private func startTimer() {
        longPressTime = 0.0
        progressBar.progress = 0.0
        longPressSetting(isEnable: true)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                return
            }

            longPressGuideLabel.isHidden = false
            let minutes = (maxTime - currentTime) / 60
            let seconds = (maxTime - currentTime) % 60
            timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
            currentTime += 1

            if currentTime > maxTime {
                timer.invalidate()
                router.moveToNextStep(
                    navigationController: self.navigationController ?? UINavigationController()
                )
                longPressGuideLabel.isHidden = true
                return
            }

            let timerBackgroundMinY = self.timerBackground.layer.presentation()?.frame.minY
            self.timeLabel.textColor = self.breakLabel.frame.minY < timerBackgroundMinY ?? .infinity
                ? .black
                : .white
        }
        timer?.fire()
    }

    private func startAnimationTimer() {
        DispatchQueue.main.async {
            self.timerHeightConstraint?.update(offset: self.view.frame.height)
            UIView.animate(withDuration: TimeInterval(self.maxTime)) {
                self.view.layoutIfNeeded()
            }
        }
    }

    private func configureNotification() {
        notificationId = UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = "시간 종료!"
        content.body = "시간이 종료되었습니다. 휴식을 취해주세요."
        let request = UNNotificationRequest(
            identifier: notificationId!,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(maxTime),
                repeats: false
            )
        )
        UNUserNotificationCenter.current()
            .add(request) { error in
                guard let error else { return }
                print(error.localizedDescription)
            }
    }
}

// MARK: - UI

extension BreakTimerViewController {
    private func addSubviews() {
        view.addSubview(timerBackground)
        view.addSubview(timeLabel)
        view.addSubview(breakLabel)
        view.addSubview(longPressGuideLabel)
        view.addSubview(progressBar)
    }

    private func setupConstraints() {
        breakLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.67)
        }
        longPressGuideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom).offset(-30)
        }
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(breakLabel.snp.bottom).offset(20)
            make.width.equalTo(240)
        }
        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(longPressGuideLabel).offset(-50)
            make.width.equalToSuperview().multipliedBy(0.8)
        }
        timerBackground.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            self.timerHeightConstraint = make.height.equalTo(0).constraint
        }
    }
}

extension BreakTimerViewController: TimeSettingViewControllerDelegate {
    func didSelectTime(time: Int) {
        maxTime = time * 60
    }
}
