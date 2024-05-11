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

// TODO: TagModalViewController 에서 선택된 값들 메인뷰컨트롤러에 표시

final class MainViewController: UIViewController{
    private let pomodoroTimeManager = PomodoroTimeManager.shared
    private let notificationId = UUID().uuidString
    private var longPressTimer: Timer?
    private var longPressTime: Float = 0.0
    private var currentPomodoro: Pomodoro?
    private var needOnboarding = false
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()

    var stepManager = PomodoroStepManger()

    private lazy var currentStepLabel = UILabel().then {
        $0.text = stepManager.label.setUpLabelInCurrentStep(
            currentStep: stepManager.router.currentStep
        )
        $0.font = .pomodoroFont.heading3()
        $0.textAlignment = .center
    }

    private let timeSettingGuideButton = UIButton().then {
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

    private let stopTimeProgressBar = UIProgressView().then {
        $0.progressViewStyle = .default
        $0.trackTintColor = UIColor.pomodoro.disabled
        $0.progressTintColor = UIColor.pomodoro.primary900
        $0.progress = 0.0
        $0.isHidden = true
    }

    private let tagButton = UIButton().then {
        $0.setTitleColor(.black, for: .normal)
        $0.titleLabel?.font = .pomodoroFont.heading6()
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let startButtonTitleLabel = UILabel().then {
        $0.text = "집중 시작하기"
        $0.font = UIFont.pomodoroFont.text1()
    }

    private let startButton = UIButton().then {
        $0.setImage(UIImage(named: "startTimerBtn"), for: .normal)
        $0.titleLabel?.font = .pomodoroFont.text1()
        $0.setTitleColor(UIColor.pomodoro.blackHigh, for: .normal)
    }

    private let appIconStackView = UIStackView().then {
        let logoIcon = UIImageView(image: UIImage(named: "dashboardIcon"))
        let titleLabel = UILabel().then {
            $0.text = "뽀모도로"
            $0.textColor = .pomodoro.primary900
            $0.font = .pomodoroFont.text1(size: 15.27)
        }

        $0.addArrangedSubview(logoIcon)
        $0.addArrangedSubview(titleLabel)
        $0.spacing = 5
        $0.axis = .horizontal
    }

    private func setupLongPressGestureRecognizer() {
        view.addGestureRecognizer(longPressGestureRecognizer)
        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPress))
        longPressGestureRecognizer.isEnabled = false
        longPressGestureRecognizer.allowableMovement = .infinity
        longPressGestureRecognizer.minimumPressDuration = 0.2
    }

    private func setupTimeLabelTapGestureRecognizer() {
        let timeLabelTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(presentTimeSettingViewController)
        )
        timeLabel.addGestureRecognizer(timeLabelTapGestureRecognizer)
        timeLabel.isUserInteractionEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stepManager.setRouterObservers()
        setUpPomodoroCurrentStepLabel()

        let documentsDirectory = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask,
            true
        )[0]

        if UserDefaults.standard.object(forKey: "needOnboarding") == nil {
            UserDefaults.standard.set(true, forKey: "needOnboarding")
            needOnboarding = true
            RealmService.write(
                Option(
                    shortBreakTime: 5,
                    longBreakTime: 20,
                    focusTime: 25,
                    isVibrate: false,
                    isTimerEffect: true
                )
            )
        }
        Log.info("needOnboarding: \(needOnboarding)")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        view.backgroundColor = .pomodoro.background

        addSubviews()
        setupConstraints()
        setupActions()
        setupLongPressGestureRecognizer()
        setupTimeLabelTapGestureRecognizer()
        setupTimeAndTag()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if pomodoroTimeManager.isRestored == true {
            pomodoroTimeManager.setupIsRestored(bool: false)
            // 다시 정보 불러왔을 때 타이머가 진행 중이라면 가장 마지막 뽀모도로 불러오기
            currentPomodoro = try? RealmService.read(Pomodoro.self).last
            startTimer()
        }
    }

    private func setupTimeAndTag() {
        if needOnboarding {
            tagButton.setTitle(nil, for: .normal)
            tagButton.setImage(UIImage(named: "onBoardingTag"), for: .normal)
            timeLabel.attributedText = .init(string: "25:00", attributes: [
                .font: UIFont.pomodoroFont.heading1(),
                .foregroundColor: UIColor.clear,
                .strokeColor: UIColor.pomodoro.blackHigh,
                .strokeWidth: 1,
            ])
            pomodoroTimeManager.setupMaxTime(time: 25 * 60)
            needOnboarding = false
        } else {
            tagButton.setTitle("Tag", for: .normal)
            tagButton.setImage(nil, for: .normal)
            timeLabel.attributedText = nil

            let option = try? RealmService.read(Option.self).first
            // 배포용
//            pomodoroTimeManager.setupMaxTime(time: (option?.focusTime ?? 25) * 60)
            // 디버깅용
            pomodoroTimeManager.setupMaxTime(time: (option?.focusTime ?? 25))

            timeLabel.text = String(
                format: "%02d:%02d",
                (pomodoroTimeManager.maxTime - pomodoroTimeManager.currentTime) / 60,
                (pomodoroTimeManager.maxTime - pomodoroTimeManager.currentTime) % 60
            )
        }
    }

    private func setupActions() {
        tagButton.addTarget(
            self,
            action: #selector(openTagModal),
            for: .touchUpInside
        )

        startButton.addTarget(self, action: #selector(startTimer), for: .touchUpInside)
    }
}

// MARK: - Action

extension MainViewController {
    @objc func didEnterBackground() {
        Log.info("max: \(pomodoroTimeManager.maxTime), curr: \(pomodoroTimeManager.currentTime)")
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
        modalViewController.selectionDelegate = self // TODO: Delegate 설정
        present(modalViewController, animated: true)
    }

    @objc private func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        stopTimeProgressBar.isHidden = false
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
            stopTimeProgressBar.isHidden = true
            longPressGuideLabel.isHidden = false
            longPressTime = 0.0
            stopTimeProgressBar.progress = 0.0
            longPressTimer?.invalidate()
        }
    }

    @objc private func setProgress() {
        longPressTime += 0.01
        stopTimeProgressBar.setProgress(longPressTime, animated: true)

        if longPressTime >= 1 {
            longPressTime = 0.0
            stopTimeProgressBar.progress = 0.0

            longPressTimer?.invalidate()

            pomodoroTimeManager.stopTimer {
                setupUIWhenTimerStart(isStopped: true)
                self.longPressGestureRecognizer.isEnabled = false
            }

            stepManager.timeSetting.initPomodoroStep()
            currentStepLabel.text = ""
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            setupTimeAndTag()

            stopTimeProgressBar.isHidden = true
            longPressGuideLabel.isHidden = true
        }
    }

    @objc private func presentTimeSettingViewController() {
        Log.info("set pomodorotime")

        if timeLabel.attributedText != nil {
            timeLabel.attributedText = nil
        }

        let timeSettingViewController = TimeSettingViewController(isSelectedTime: false, delegate: self)
        if let sheet = timeSettingViewController.sheetPresentationController {
            sheet.detents = [
                .custom { context in
                    context.maximumDetentValue * 0.95
                },
            ]
            sheet.preferredCornerRadius = 40
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(timeSettingViewController, animated: true)
    }

    private func setupNotification() {
        let content = UNMutableNotificationContent()
        content.title = "시간 종료!"
        content.body = "시간이 종료되었습니다. 휴식을 취해주세요."

        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(pomodoroTimeManager.maxTime),
                repeats: false
            )
        )

        UNUserNotificationCenter.current()
            .add(request)
    }

    private func setupUIWhenTimerStart(isStopped: Bool) {
        if isStopped == false {
            startButtonTitleLabel.isHidden = true
            startButton.isHidden = true
            timeSettingGuideButton.isHidden = true
        } else {
            startButtonTitleLabel.isHidden = false
            startButton.isHidden = false
            timeSettingGuideButton.isHidden = false
        }
    }

    @objc private func startTimer() {
        Log.debug("maxTime: \(pomodoroTimeManager.maxTime)")
        guard pomodoroTimeManager.maxTime != 0 else {
            return
        }

        if timeLabel.attributedText != nil {
            timeLabel.attributedText = nil
        }

        longPressTime = 0.0
        stopTimeProgressBar.progress = 0.0

        tagButton.isUserInteractionEnabled = false
        longPressGuideLabel.isHidden = false
        longPressGestureRecognizer.isEnabled = true
        

        // 강제종료 이후 정보 불러온 상황이 아닐때 (클릭 상황)
        if pomodoroTimeManager.isRestored == false {
            let prevPomodoro = try? RealmService.read(Pomodoro.self).last

            // 이전 뽀모도로 끝난 경우
            if prevPomodoro?.phase == 0 || prevPomodoro == nil {
                RealmService.createPomodoro(tag: "임시")
            }
            currentPomodoro = try? RealmService.read(Pomodoro.self).last
        }

        pomodoroTimeManager.startTimer(timerBlock: { [self] timer, currentTime, maxTime in
            setupUIWhenTimerStart(isStopped: false)

            let minutes = (maxTime - currentTime) / 60
            let seconds = (maxTime - currentTime) % 60

            if minutes == 0, seconds == 0 {
                timer.invalidate()
                setupUIWhenTimerStart(isStopped: true)

                RealmService.update(currentPomodoro!) { updatedPomodoro in
                    updatedPomodoro.phase += 1
                    if updatedPomodoro.phase == 5 {
                        updatedPomodoro.isSuccess = true
                        updatedPomodoro.phase = 0
                    }
                }

                let isVibrate = try? RealmService.read(Option.self).first?.isVibrate
                if isVibrate ?? false {
                    HapticService.hapticNotification(type: .warning)
                }

                setUpPomodoroCurrentStep()

                longPressGestureRecognizer.isEnabled = false
            }

            timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        })

        setupNotification()
    }

    private func setUpPomodoroCurrentStep() {
        guard let navigationController else {
            assertionFailure("navigationController should exist")
            return
        }
        stepManager.router.moveToNextStep(
            navigationController: navigationController
        )
    }

    private func setUpPomodoroCurrentStepLabel() {
        stepManager.timeSetting.setUptimeInCurrentStep()
        currentStepLabel.text = stepManager.label.setUpLabelInCurrentStep(
            currentStep: stepManager.router.currentStep
        )
        if stepManager.router.currentStep != .start {
            timeSettingGuideButton.isHidden = true
        } else {
            timeSettingGuideButton.isHidden = false
        }
    }
}

// MARK: - UI

extension MainViewController {
    private func addSubviews() {
        view.addSubview(timeLabel)
        view.addSubview(appIconStackView)
        view.addSubview(startButtonTitleLabel)
        view.addSubview(startButton)
        view.addSubview(timeSettingGuideButton)
        view.addSubview(tagButton)
        view.addSubview(longPressGuideLabel)
        view.addSubview(stopTimeProgressBar)
        view.addSubview(currentStepLabel)
    }

    private func setupConstraints() {
        appIconStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.equalTo(30)
        }
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
            make.size.equalTo(CGSize(width: 70, height: 25))
        }
        timeSettingGuideButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(timeLabel).offset(-70)
        }
        startButtonTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(startButton).offset(-80)
        }
        startButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
        }
        longPressGuideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom).offset(-50)
        }
        stopTimeProgressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(longPressGuideLabel)
            make.width.equalToSuperview().multipliedBy(0.8)
        }
    }
}

extension MainViewController: TimeSettingViewControllerDelegate {
    func didSelectTime(time: Int) {
        pomodoroTimeManager.setupMaxTime(time: time)
        guard let option = try? RealmService.read(Option.self).first else { return }
        RealmService.update(option) { opt in
            opt.focusTime = time
        }
        setupTimeAndTag()
    }
}

extension MainViewController: TagModalViewControllerDelegate {
    func tagSelected(tagName: String, tagColor: String) {
        let backgroundColor = TagCase(rawValue: tagColor)?.backgroundColor ?? .gray
        let titleColor = TagCase(rawValue: tagColor)?.typoColor ?? .gray

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tagButton.setTitle(tagName, for: .normal)
            self.tagButton.backgroundColor = titleColor
            self.tagButton.setTitleColor(.white, for: .normal)
        }
        print("Selected Tag: \(tagName), Color: \(tagColor)")
    }
}

