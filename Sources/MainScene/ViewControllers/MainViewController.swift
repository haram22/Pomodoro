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
    let onBoardingManager = OnboardingManager.shared

    private var isOnboarding: Bool = true
    private var notificationId: String?
    private var longPressTimer: Timer?
    private var longPressTime: Float = 0.0
    var stepManager = PomodoroStepManger()
    private var currentPomodoro: Pomodoro?

    private let longPressGestureRecognizer = UILongPressGestureRecognizer()

    // 시간라벨 누르게 하는 GestureRecognizer
    private let timeLabelTapGestureRecognizer = UITapGestureRecognizer()

    lazy var currentStepLabel = UILabel().then {
        $0.text = stepManager.label.setUpLabelInCurrentStep(currentStep: stepManager.router.currentStep)
        $0.font = .pomodoroFont.heading3()
        $0.textAlignment = .center
    }

    private let pressToSetButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .pomodoro.primary900
        var attributedTitle = AttributedString("터치해서 설정하기")
        attributedTitle.font = UIFont.pomodoroFont.heading6()
        config.attributedTitle = attributedTitle
        $0.configuration = config
    }

    private var timeLabel = UILabel().then {
        $0.textColor = UIColor.pomodoro.blackHigh
        $0.textAlignment = .center
        $0.font = UIFont.pomodoroFont.heading1()
    }

    private let longPressGuideLabel = UILabel().then {
        $0.text = "길게 클릭해서 타이머를 정지할 수 있어요"
        $0.textAlignment = .center
        $0.textColor = .lightGray
        $0.font = UIFont.pomodoroFont.heading6()
        $0.isHidden = true
    }

    private let progressBar = UIProgressView().then {
        $0.progressViewStyle = .default
        $0.trackTintColor = UIColor.pomodoro.disabled
        $0.progressTintColor = UIColor.pomodoro.primary900
        $0.progress = 0.0
        $0.isHidden = true
    }

    private lazy var tagButton = UIButton().then {
        if isOnboarding == true {
            $0.setImage(UIImage(named: "onBoardingTag"), for: .normal)
        } else {
            $0.setTitle("Tag", for: .normal)
            $0.setTitleColor(.black, for: .normal)
            $0.titleLabel?.font = .pomodoroFont.heading6()
        }

        $0.addTarget(
            self,
            action: #selector(openTagModal),
            for: .touchUpInside
        )
    }

    private let startTimerLabel = UILabel().then {
        $0.text = "집중 시작하기"
        $0.font = UIFont.pomodoroFont.text1()
    }

    private lazy var startTimerButton = UIButton().then {
        $0.setImage(UIImage(named: "startTimerBtn"), for: .normal)
        $0.titleLabel?.font = .pomodoroFont.text1()
        $0.setTitleColor(UIColor.pomodoro.blackHigh, for: .normal)
        $0.addTarget(self, action: #selector(startTimer), for: .touchUpInside)
    }

    private let appIconStackView = UIStackView()

    private func setupPomodoroIcon() {
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

    private func setupLongPressGestureRecognizer() {
        view.addGestureRecognizer(longPressGestureRecognizer)
        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPress))
        longPressGestureRecognizer.isEnabled = false
        longPressGestureRecognizer.allowableMovement = .infinity
        longPressGestureRecognizer.minimumPressDuration = 0.2
    }

    private func setupTimeLabelTapGestureRecognizer() {
        timeLabel.addGestureRecognizer(timeLabelTapGestureRecognizer)
        timeLabel.isUserInteractionEnabled = true
        timeLabelTapGestureRecognizer.addTarget(self, action: #selector(setPomodoroTime))
        timeLabelTapGestureRecognizer.isEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // OnBoarding 체크
        isOnboarding = onBoardingManager.checkOnboarding()

        stepManager.setRouterObservers()
        setUpPomodoroCurrentStepLabel()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        view.backgroundColor = .pomodoro.background

        addSubviews()
        setupPomodoroIcon()
        setupConstraints()

        setupLongPressGestureRecognizer()
        setupTimeLabelTapGestureRecognizer()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isOnboarding == true {
            pomodoroTimeManager.setupMaxTime(time: 25 * 60)
        }
        updateTimeLabel()

        if pomodoroTimeManager.isRestored == true {
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
        timeLabel.text = String(
            format: "%02d:%02d",
            (pomodoroTimeManager.maxTime - pomodoroTimeManager.currentTime) / 60,
            (pomodoroTimeManager.maxTime - pomodoroTimeManager.currentTime) % 60
        )
    }

    @objc private func openTagModal() {
        let modalViewController = TagModalViewController()
        modalViewController.modalPresentationStyle = .fullScreen
        present(modalViewController, animated: true)
    }

    @objc private func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        progressBar.isHidden = false
        longPressGuideLabel.isHidden = true

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
            longPressGuideLabel.isHidden = false
            longPressTime = 0.0
            progressBar.progress = 0.0
            longPressTimer?.invalidate()
        }
    }

    @objc private func setProgress() {
        longPressTime += 0.01
        progressBar.setProgress(longPressTime, animated: true)

        if longPressTime >= 1 {
            longPressTime = 0.0
            progressBar.progress = 0.0

            longPressTimer?.invalidate()

            database.update(currentPomodoro!) { pomodoro in
                pomodoro.phase = 0
                pomodoro.isSuccess = false
            }

            pomodoroTimeManager.stopTimer {
                setupUIWhenTimerStart(isStopped: true)
                self.longPressGestureRecognizer.isEnabled = false
            }

            stepManager.timeSetting.initPomodoroStep()
            currentStepLabel.text = ""

            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            updateTimeLabel()

            progressBar.isHidden = true
            longPressGuideLabel.isHidden = true
            timeLabelTapGestureRecognizer.isEnabled = true
        }
    }

    @objc private func setPomodoroTime() {
        print("set pomodorotime")
        let timeSettingViewController = TimeSettingViewController(isSelectedTime: false, delegate: self)
        if let sheet = timeSettingViewController.sheetPresentationController {
            sheet.detents = [
                .custom { context in
                    context.maximumDetentValue * 0.95
                }
            ]
            sheet.preferredCornerRadius = 40
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(timeSettingViewController, animated: true)
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
            startTimerLabel.isHidden = true
            startTimerButton.isHidden = true
            pressToSetButton.isHidden = true
            timeLabelTapGestureRecognizer.isEnabled = true
        } else {
            startTimerLabel.isHidden = false
            startTimerButton.isHidden = false
            pressToSetButton.isHidden = false
            timeLabelTapGestureRecognizer.isEnabled = true
        }
    }

    @objc private func startTimer() {
        guard pomodoroTimeManager.maxTime != 0 else {
            return
        }

        longPressTime = 0.0
        progressBar.progress = 0.0

        longPressGuideLabel.isHidden = false
        longPressGestureRecognizer.isEnabled = true

        // 강제종료 이후 정보 불러온 상황이 아닐때 (클릭 상황)
        if pomodoroTimeManager.isRestored == false {
            let prevPomodoro = database.read(Pomodoro.self).last

            // 이전 뽀모도로 끝난 경우
            if prevPomodoro?.phase == 0 || prevPomodoro == nil {
                database.createPomodoro(tag: "임시")
            }
            currentPomodoro = database.read(Pomodoro.self).last
        }

        pomodoroTimeManager.startTimer(timerBlock: { [self] timer, currentTime, maxTime in
            setupUIWhenTimerStart(isStopped: false)

            let minutes = (maxTime - currentTime) / 60
            let seconds = (maxTime - currentTime) % 60

            if minutes == 0, seconds == 0 {
                timer.invalidate()
                setupUIWhenTimerStart(isStopped: true)
                database.update(currentPomodoro!) { updatedPomodoro in
                    updatedPomodoro.phase += 1
                    if updatedPomodoro.phase == 5 {
                        updatedPomodoro.isSuccess = true
                        updatedPomodoro.phase = 0
                    }
                }

                setUpPomodoroCurrentStep()

                longPressGestureRecognizer.isEnabled = false
            }

            timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        })

        setupNotification()
    }

    private func setUpPomodoroCurrentStep() {
        stepManager.router.moveToNextStep(
            navigationController:
            navigationController ?? UINavigationController()
        )
    }

    private func setUpPomodoroCurrentStepLabel() {
        stepManager.timeSetting.setUptimeInCurrentStep()
        currentStepLabel.text = stepManager.label.setUpLabelInCurrentStep(
            currentStep: stepManager.router.currentStep
        )
    }
}

// MARK: - UI

extension MainViewController {
    private func addSubviews() {
        view.addSubview(timeLabel)
        view.addSubview(appIconStackView)
        view.addSubview(startTimerLabel)
        view.addSubview(startTimerButton)
        view.addSubview(pressToSetButton)
        view.addSubview(tagButton)
        view.addSubview(longPressGuideLabel)
        view.addSubview(progressBar)
        view.addSubview(currentStepLabel)
    }

    private func setupConstraints() {
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
        }
        currentStepLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(timeLabel.snp.top).offset(-23)
        }
        tagButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timeLabel.snp.bottom).offset(20)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.height.equalTo(50)
        }
        pressToSetButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(timeLabel).offset(-70)
        }
        startTimerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(startTimerButton).offset(-80)
        }
        startTimerButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
        }
        longPressGuideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom).offset(-50)
        }
        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(longPressGuideLabel)
            make.width.equalToSuperview().multipliedBy(0.8)
        }
    }
}

extension MainViewController: TimeSettingViewControllerDelegate {
    func didSelectTime(time: Int) {
        pomodoroTimeManager.setupMaxTime(time: time)
        updateTimeLabel()
    }
}

extension MainViewController: TagModalViewControllerDelegate {
    func tagSelected(tag _: String) {
        // TODO: 선택된 태그 정보 전달
    }
}
