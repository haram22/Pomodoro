//
//  DashboardPieChartCell.swift
//  Pomodoro
//
//  Created by 김하람 on 1/30/24.
//  Copyright © 2024 io.hgu. All rights reserved.
//

import DGCharts
import SnapKit
import UIKit

final class DashboardPieChartCell: UICollectionViewCell {
    private var selectedDate: Date = .init()
    private var dayData: [String] = []
    private var priceData: [Double] = [10]
    var tagLabelHeightConstraint: Constraint?
    let legendStackView = UIStackView()
    private let pieBackgroundView = UIView().then { view in
        view.layer.cornerRadius = 20
        view.backgroundColor = .white
    }

    private let donutPieChartView = PieChartView().then { chart in
        chart.noDataText = "출력 데이터가 없습니다."
        chart.noDataFont = .systemFont(ofSize: 20)
        chart.noDataTextColor = .black
        chart.holeColor = .clear
        chart.backgroundColor = .clear
        chart.drawSlicesUnderHoleEnabled = false
        chart.holeRadiusPercent = 0.55
        chart.drawEntryLabelsEnabled = false
        chart.highlightPerTapEnabled = false
        chart.legend.enabled = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(pieBackgroundView)
        pieBackgroundView.addSubview(donutPieChartView)
        backgroundColor = .clear
        layer.cornerRadius = 20
        setTagLabel()
        setupPieChart()
        setLegendLabel()
        setPieChartData(for: Date(), dateType: .day)
    }

    private func setTagLabel() {
        let tagLabel = UILabel().then {
            contentView.addSubview($0)
            $0.text = "태그 비율"
            $0.textColor = .pomodoro.blackHigh
            $0.font = .pomodoroFont.heading4()
        }
        tagLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(10)
        }
    }

    private func calculateFocusTimePerTag(for selectedDate: Date) -> [String: Int] {
        let calendar = Calendar.current
        var focusTimePerTag = [String: Int]()
        let filteredSessions = PomodoroData.dummyData.filter { session in
            calendar.isDate(session.participateDate, inSameDayAs: selectedDate)
        }
        for session in filteredSessions {
            focusTimePerTag[session.tagId, default: 0] += session.focusTime
        }
        return focusTimePerTag
    }

    private func setupPieChart() {
        pieBackgroundView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(30)
            self.tagLabelHeightConstraint = make.height.equalTo(0).constraint
        }
        donutPieChartView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(donutPieChartView.snp.width)
        }
    }

    private func entryData(values: [Double]) -> [ChartDataEntry] {
        var pieDataEntries: [ChartDataEntry] = []
        for index in 0 ..< values.count {
            let pieDataEntry = ChartDataEntry(x: Double(index), y: values[index])
            pieDataEntries.append(pieDataEntry)
        }
        return pieDataEntries
    }

    private func calculateFocusTimePerTag(from startDate: Date, to endDate: Date) -> [String: Int] {
        var focusTimePerTag = [String: Int]()
        let filteredSessions = PomodoroData.dummyData.filter { session in
            session.participateDate >= startDate && session.participateDate < endDate
        }
        for session in filteredSessions {
            focusTimePerTag[session.tagId, default: 0] += session.focusTime
        }
        return focusTimePerTag
    }

    func setPieChartData(for date: Date, dateType: DashboardDateType) {
        let (startDate, endDate) = getDateRange(for: date, dateType: dateType)
        let focusTimePerTag = calculateFocusTimePerTag(from: startDate, to: endDate)
        let sortedFocusTimePerTag = focusTimePerTag.sorted { $0.value > $1.value }
        let pieChartDataEntries = sortedFocusTimePerTag.map {
            PieChartDataEntry(value: Double($1), label: $0)
        }

        let pieChartDataSet = PieChartDataSet(entries: pieChartDataEntries, label: "").then {
            let colors: [UIColor] = [.systemTeal, .systemPink, .systemIndigo]
            var dataSetColors: [UIColor] = []
            for index in 0 ..< pieChartDataEntries.count {
                let color = colors[index % colors.count]
                dataSetColors.append(color)
            }
            $0.colors = dataSetColors
            $0.drawValuesEnabled = false
        }
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        donutPieChartView.data = pieChartData

        let totalFocusTime = focusTimePerTag.reduce(0) { $0 + $1.value }
        updatePieChartText(totalFocusTime: totalFocusTime)
        updateLegendLabel(with: focusTimePerTag)
    }

    private func setLegendLabel() {
        legendStackView.axis = .vertical
        legendStackView.distribution = .equalSpacing
        legendStackView.alignment = .leading
        legendStackView.spacing = 8
        legendStackView.backgroundColor = .clear

        donutPieChartView.addSubview(legendStackView)
        legendStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(donutPieChartView.snp.bottom)
        }
    }

    private func updateLegendLabel(with focusTimePerTag: [String: Int]) {
        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let sortedFocusTime = focusTimePerTag.sorted { $0.value > $1.value }
        let totalFocusTime = sortedFocusTime.reduce(0) { $0 + $1.value }
        for (tagId, focusTime) in sortedFocusTime {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 20)
            let days = focusTime / (24 * 60)
            let hours = (focusTime % (24 * 60)) / 60
            let minutes = focusTime % 60
            var timeText = ""
            if days > 0 {
                timeText += "\(days)일 "
            }
            if hours > 0 || days > 0 {
                timeText += "\(hours)시간 "
            }
            timeText += "\(minutes)분"
            let percentage = (Double(focusTime) / Double(totalFocusTime)) * 100
            label.text = "\(tagId): \(timeText) (\(String(format: "%.0f", percentage))%)"

            legendStackView.addArrangedSubview(label)
        }

        tagLabelHeightConstraint?.update(offset: 360 + 25 * sortedFocusTime.count)
        UIView.animate(withDuration: 0) {
            self.layoutIfNeeded()
        }
    }

    private func updatePieChartText(totalFocusTime: Int) {
        let days = totalFocusTime / (24 * 60)
        let hours = (totalFocusTime % (24 * 60)) / 60
        let minutes = totalFocusTime % 60
        var totalTimeText = "합계\n"
        if days > 0 {
            totalTimeText += "\(days)일"
        }
        if hours > 0 || days > 0 {
            totalTimeText += "\(hours)시간"
        }
        totalTimeText += "\(minutes)분"
        donutPieChartView.centerText = totalTimeText
    }

    private func getDateRange(for date: Date, dateType: DashboardDateType) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        switch dateType {
        case .day:
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return (startOfDay, startOfDay)
            }
            return (startOfDay, endOfDay)
        case .week:
            guard let startOfWeek = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)
            else {
                return (date, date)
            }
            return (startOfWeek, endOfWeek)
        case .month:
            guard let monthStartDate = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)),
                let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: monthStartDate),
                let monthEndDate = calendar.date(byAdding: .day, value: -1, to: nextMonthDate)
            else {
                return (date, date)
            }
            return (monthStartDate, monthEndDate)
        case .year:
            guard let yearStartDate = calendar.date(from: calendar.dateComponents([.year], from: date)),
                  let nextYearDate = calendar.date(byAdding: .year, value: 1, to: yearStartDate),
                  let yearEndDate = calendar.date(byAdding: .day, value: -1, to: nextYearDate)
            else {
                return (date, date)
            }
            return (yearStartDate, yearEndDate)
        }
    }
}

extension DashboardPieChartCell: DashboardTabDelegate {
    func dateArrowButtonDidTap(data date: Date) {
        selectedDate = date
    }
}
