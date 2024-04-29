//
//  PomodoroRouter.swift
//  Pomodoro
//
//  Created by 진세진 on 2/26/24.
//
import UIKit

enum PomodoroTimerStep: Equatable {
    case start
    case focus(count: Int)
    case rest(count: Int)
    case end
}

protocol PomodoroStepObserver: AnyObject {
    func didPomodoroStepChange(to step: PomodoroTimerStep)
}

// - MARK: PomodoroStepTimeChage - pomodoroStep의 변화에 따른 스텝단계의 변화와 navigator 관리
final class PomodoroRouter {
    static let shared = PomodoroRouter()
    private let pomodoroTimeManager = PomodoroTimeManager.shared
    let maxStep = 3
    var pomodoroCount: Int = 0

    var observers: [PomodoroStepObserver] = []
    var currentStep: PomodoroTimerStep = .start {
        didSet {
            notifyObservers()
        }
    }

    func addObservers(observer: PomodoroStepObserver) {
        observers.append(observer)
    }

    func notifyObservers() {
        for observer in observers {
            observer.didPomodoroStepChange(to: currentStep)
        }
    }

    func moveToNextStep(navigationController: UINavigationController) {
        currentStep = checkCurrentStep()
        Log.info(currentStep)
        navigatorToCurrentStep(
            currentStep: currentStep,
            navigationController: navigationController
        )
    }

    func savePomodoroStepCounter() {
        let data = try? RealmService.read(Pomodoro.self)
        guard let currentData = data?.last else {
            return
        }
        RealmService.update(currentData) { data in
            data.phase = self.pomodoroCount
        }
    }

    func navigatorToCurrentStep(
        currentStep: PomodoroTimerStep,
        navigationController: UINavigationController
    ) {
        let pomodoroMainViewController = MainViewController()
        let pomodoroMainPageViewController = MainPageViewController()
        let breakTimerViewController = BreakTimerViewController()

        switch currentStep {
        case .start:
            pomodoroMainViewController.stepManager.router = self
            navigationController.pushViewController(pomodoroMainPageViewController, animated: true)
        case .focus:
            pomodoroMainViewController.stepManager.router = self
            navigationController.pushViewController(pomodoroMainPageViewController, animated: true)
        case .rest:
            if maxStep < pomodoroCount {
                breakTimerViewController.stepManager.router = self
                navigationController.popToRootViewController(animated: true)
            } else {
                breakTimerViewController.stepManager.router = self
                navigationController.pushViewController(breakTimerViewController, animated: true)
            }
        case .end:
            navigationController.popToRootViewController(animated: true)
        }
    }

    func checkCurrentStep() -> PomodoroTimerStep {
        switch currentStep {
        case .start:
            pomodoroCount = 0
            currentStep = .rest(count: pomodoroCount)
        case let .focus(count):
            currentStep = .rest(count: count)
        case var .rest(count):
            count = pomodoroCount
            if count < maxStep {
                pomodoroCount += 1
                currentStep = .focus(count: pomodoroCount)
            } else {
                currentStep = .end
                currentStep = .start
            }
        case .end:
            pomodoroCount = 0
        }
        return currentStep
    }
}

// - MARK: PomodoroStepTimeChage - pomodoroStep 변화에 따른 시간의 변화를 관리하는 클래스
final class PomodoroStepTimeChange {
    private let pomodoroTimeManager = PomodoroTimeManager.shared

    private let maxStep = PomodoroRouter.shared.maxStep
    private let stepDataBase = RealmService.self
    private var pomodoroCurrentCount = PomodoroRouter.shared.pomodoroCount

    private var currentStep: PomodoroTimerStep?
    private var shortBreakTime: Int?
    private var longBreakTime: Int?

    func setUptimeInCurrentStep() {
        updateCurrentPomodoroStepData()
        guard let currentStep else { return }
        switch currentStep {
        case .start:
            pomodoroTimeManager.setupCurrentTime(curr: 0)
            pomodoroTimeManager.setupMaxTime(time: 0)
        case .focus:
            pomodoroTimeManager.setupCurrentTime(curr: 0)
        case .rest:
            pomodoroTimeManager.setupCurrentTime(curr: 0)
        case .end:
            pomodoroTimeManager.setupCurrentTime(curr: 0)
            pomodoroTimeManager.setupMaxTime(time: 0)
        }
    }

    func setUpBreakTime() -> Int {
        let options = (try? RealmService.read(Option.self).first) ?? Option()
        if pomodoroCurrentCount < 3 {
            return options.shortBreakTime
        } else {
            return options.longBreakTime
        }
    }

    func initPomodoroStep() {
        pomodoroCurrentCount = 0
        pomodoroTimeManager.setupMaxTime(time: 0)
        pomodoroTimeManager.setupCurrentTime(curr: 0)
        currentStep = .start
        isFailedPomodoroStep()
    }

    func updateCurrentPomodoroStepData() {
        let data = (try? RealmService.read(Pomodoro.self).last) ?? Pomodoro()
        stepDataBase.update(data) { data in
            data.phase += 1
            if data.phase == 5 {
                data.isSuccess = true
            }
        }
    }

    func isFailedPomodoroStep() {
        let currenttime = pomodoroTimeManager.currentTime
        let data = (try? RealmService.read(Pomodoro.self).last) ?? Pomodoro()
        if currenttime < 60, data.phase == 1 {
            stepDataBase.delete(data)
        } else {
            stepDataBase.update(data) { data in
                data.isSuccess = false
            }
        }
    }
}

extension PomodoroStepTimeChange: PomodoroStepObserver {
    func didPomodoroStepCounterChange(stepCounter counter: Int) {
        pomodoroCurrentCount = counter
    }

    func didPomodoroStepChange(to step: PomodoroTimerStep) {
        currentStep = step
    }
}

// - MARK: PomodoroStepLabel : 현재 스텝을 label로 보여주기
final class PomodoroStepLabel {
    private var pomodoroCurrentCount = PomodoroRouter.shared.pomodoroCount
    private var currentStep: PomodoroTimerStep = .start

    func setUpLabelInCurrentStep(currentStep: PomodoroTimerStep) -> String {
        switch currentStep {
        case .start:
            return ""
        case var .rest(count), var .focus(count):
            count = pomodoroCurrentCount
            if count == .zero {
                return ""
            }
            return "\(count + 1) 회차"
        case .end:
            return ""
        }
    }
}

extension PomodoroStepLabel: PomodoroStepObserver {
    func didPomodoroStepChange(to step: PomodoroTimerStep) {
        _ = setUpLabelInCurrentStep(currentStep: step)
    }
}
