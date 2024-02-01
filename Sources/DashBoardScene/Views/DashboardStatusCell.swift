//
//  DashboardStatusCell.swift
//  Pomodoro
//
//  Created by 김하람 on 1/30/24.
//  Copyright © 2024 io.hgu. All rights reserved.
//

import DGCharts
import SnapKit
import Then
import UIKit

final class DashboardStatusCell: UICollectionViewCell {
    private let participateLabel = UILabel()
    private let countLabel = UILabel()
    private let achieveLabel = UILabel()
    private let failLabel = UILabel()
    private var selectedDate: Date = Date()
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("이 생성자를 사용하려면 스토리보드를 구현해주세요.")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    private func setupLabel(_ label: UILabel, topOffset: CGFloat, centerXOffset: CGFloat) {
        label.textColor = .white
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topOffset)
            make.centerX.equalToSuperview().offset(centerXOffset)
        }
    }
    
    private func setupDivider(isHorizontal: Bool, length: CGFloat, offset: CGFloat) {
        let divider = UIView()
        divider.backgroundColor = .white
        contentView.addSubview(divider)
        divider.snp.makeConstraints { make in
            if isHorizontal {
                make.width.equalTo(length)
                make.height.equalTo(1)
            } else {
                make.width.equalTo(1)
                make.height.equalTo(length)
            }
            make.top.equalToSuperview().offset(offset)
            make.centerX.equalToSuperview()
        }
    }
    
    private func setupUI() {
        setupLabel(participateLabel, topOffset: 70, centerXOffset: -100)
        setupLabel(countLabel, topOffset: 70, centerXOffset: 50)
        setupLabel(achieveLabel, topOffset: 160, centerXOffset: -100)
        setupLabel(failLabel, topOffset: 160, centerXOffset: 50)
        setupDivider(isHorizontal: true, length: 325, offset: 130)
        setupDivider(isHorizontal: false, length: 155, offset: 50)
        layer.cornerRadius = 20
        backgroundColor = .black
    }
    
    func updateUI(for date: Date, isWeek: Bool = false) {
        let startDate: Date
        let endDate: Date
        
        if isWeek {
            let weekDates = getStartAndEndDateOfWeek(for: date)
            startDate = weekDates.start
            endDate = weekDates.end
        } else {
            startDate = date
            endDate = date
        }
        
        let totalParticipate = PomodoroData.dummyData.filter { $0.participateDate >= startDate && $0.participateDate < endDate }
        let participateCount = totalParticipate.count
        
        let filteredData = PomodoroData.dummyData.filter {
            $0.participateDate >= startDate && $0.participateDate < endDate
        }
        let totalSuccessCount = filteredData.filter { $0.success }.count
        let totalFailureCount = filteredData.filter { !$0.success }.count
        
        participateLabel.text = "참여일 \(participateCount)"
        countLabel.text = "횟수 \(filteredData.count)"
        achieveLabel.text = "달성 \(totalSuccessCount)"
        failLabel.text = "실패 \(totalFailureCount)"
    }
    
    private func getStartAndEndDateOfWeek(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return (date, date)
        }
        let startDate = weekInterval.start
        let endDate = weekInterval.end
        return (startDate, endDate)
    }
}

// MARK: - DayViewControllerDelegate
extension DashboardStatusCell: DayViewControllerDelegate {
    func dateArrowButtonDidTap(data date: Date) {
        selectedDate = date
    }
}
