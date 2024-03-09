//
//  DashBoardTabViewController.swift
//  Pomodoro
//
//  Created by 진세진 on 2023/11/06.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import PomodoroDesignSystem
import SnapKit
import UIKit

final class DashBoardTabViewController: UIViewController {
    private let database = DatabaseManager.shared
    private enum SegmentItem: Int {
        case day
        case week
        case month
        case year
    }

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let appIconStackView = UIStackView()
    private let totalParticipateDate = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pomodoro.background
        setupTopView()
        setupSegmentedControl()
        setupContainerView()
        segmentChanged()
    }

    private func caculateTotalParticipate() -> Int {
        let data = database.read(Pomodoro.self)
        let filteredData = data.filter { $0.participateDate < Date() }
        let participateDates = Set(filteredData.map { Calendar.current.startOfDay(for: $0.participateDate) })
        return participateDates.count
    }

    private func setupTopView() {
        let totalDate = caculateTotalParticipate()
        let logoIcon = UIImageView().then {
            $0.image = UIImage(named: "dashboardIcon")
        }
        let appName = UILabel().then {
            $0.text = "뽀모도로"
            $0.textColor = .pomodoro.primary900
            $0.font = .pomodoroFont.text1(size: 15.27)
        }

        appIconStackView.then {
            view.addSubview($0)
            $0.addArrangedSubview(logoIcon)
            $0.addArrangedSubview(appName)
            $0.spacing = 5
            $0.axis = .horizontal
            $0.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.leading.equalTo(30)
            }
        }

        titleLabel.then {
            view.addSubview($0)
            $0.text = "나의 통계"
            $0.textColor = .pomodoro.blackHigh
            $0.font = .pomodoroFont.heading3(size: 18)
            $0.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(appIconStackView.snp.bottom).offset(20)
            }
        }
        totalParticipateDate.then {
            view.addSubview($0)
            $0.text = "총 \(totalDate)일 뽀모도로 하셨어요!"
            $0.font = .pomodoroFont.heading3(size: 15.7)
            $0.textColor = .pomodoro.primary900
            $0.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.leading.equalTo(30)
            }
        }
    }

    private func setupContainerView() {
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(tabBarControl.snp.bottom).offset(32)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private let tabBarControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["일", "주", "월", "년"])
        segmentedControl.backgroundColor = .white
        segmentedControl.selectedSegmentTintColor = .pomodoro.primary900
        segmentedControl.layer.cornerRadius = 50
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.pomodoro.blackHigh,
            .font: UIFont.pomodoroFont.heading5(size: 15.7)
        ]
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.pomodoroFont.heading5(size: 15.7)
        ]
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()

    private func setupSegmentedControl() {
        view.addSubview(tabBarControl)
        tabBarControl.snp.makeConstraints { make in
            make.top.equalTo(totalParticipateDate.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
            make.leading.equalTo(30)
            make.trailing.equalTo(-30)
        }
        tabBarControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    private func displayViewController(_ currentViewType: DashboardDateType) {
        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }

        let viewController = DashboardBaseViewController()
        viewController.dashboardDateType = currentViewType
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.frame = containerView.bounds
        viewController.didMove(toParent: self)
    }

    @objc private func segmentChanged() {
        if let selectedViewController = DashboardDateType(
            rawValue: tabBarControl.selectedSegmentIndex) {
            displayViewController(selectedViewController)
        }
    }
}
