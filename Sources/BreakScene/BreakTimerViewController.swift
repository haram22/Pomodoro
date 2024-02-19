//
//  BreakTimerViewController.swift
//  Pomodoro
//
//  Created by 김하람 on 2/19/24.
//

import PanModal
import SnapKit
import Then
import UIKit

final class BreakTimerViewController: UIViewController {
    private var timer: Timer?
    private var notificationId: String?
    private var currentTime = 0
    private var maxTime = 25 // * 60
    private var longPressTimer: Timer?
    private var longPressTime: Float = 0.0

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
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        $0.addTarget(
            self,
            action: #selector(openTagModal),
            for: .touchUpInside
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubviews()
        setupConstraints()

        longPressSetting(isEnable: false)
        startTimer()
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
        presentPanModal(modalViewController)
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
        longPressGuideLabel.isHidden = true
    }

    @objc private func timeSetting() {
        let timeSettingviewController = TimeSettingViewController(isSelectedTime: false, delegate: self)
    }

    @objc private func startTimer() {
        longPressTime = 0.0
        progressBar.progress = 0.0

        longPressSetting(isEnable: true)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.longPressGuideLabel.isHidden = false

            let minutes = (self.maxTime - self.currentTime) / 60
            let seconds = (self.maxTime - self.currentTime) % 60

            self.timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
            self.currentTime += 1

            if self.currentTime > self.maxTime {
                timer.invalidate()
                self.longPressGuideLabel.isHidden = true
                let mainVC = MainViewController()
                self.navigationController?.pushViewController(mainVC, animated: true)
            }
        }
        timer?.fire()

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
        view.addSubview(timeLabel)
        view.addSubview(tagButton)
        view.addSubview(longPressGuideLabel)
        view.addSubview(progressBar)
    }

    private func setupConstraints() {
        tagButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timeLabel.snp.bottom).offset(20)
        }
        longPressGuideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom).offset(-30)
        }
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.67)
        }
        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(longPressGuideLabel).offset(-50)
            make.width.equalToSuperview().multipliedBy(0.8)
        }
    }
}

extension BreakTimerViewController: TimeSettingViewControllerDelegate {
    func didSelectTime(time: Int) {
        maxTime = time * 60
    }
}