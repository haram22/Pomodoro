//
//  WeekViewController.swift
//  Pomodoro
//
//  Created by 김하람 on 2023/11/13.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import UIKit
import SnapKit

final class WeekViewController: UIViewController {
    private var delegate : DayViewControllerDelegate?
    private let dashboardStatusCell = DashboardStatusCell()
    private let dashboardPieChartCell = DashboardPieChartCell()
    private var selectedDate = Date()
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter().then {
        $0.dateStyle = .long
        $0.dateFormat = "MM월 dd일"
    }
    
    private lazy var dateLabel = UILabel().then {
        $0.text = dateFormatter.string(from: selectedDate)
        $0.textAlignment = .center
        $0.textColor = .black
    }
    
    private lazy var previousButton = UIButton().then {
        $0.setImage(UIImage(systemName: "arrowtriangle.backward")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        $0.addTarget(self, action: #selector(goToPreviousWeek), for: .touchUpInside)
    }
    
    private lazy var nextButton = UIButton().then {
        $0.setImage(UIImage(systemName: "arrowtriangle.right")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        $0.addTarget(self, action: #selector(goToNextWeek), for: .touchUpInside)
    }
    
    private lazy var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: self.getLayout()).then {
        $0.isScrollEnabled = true
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = true
        $0.contentInset = .zero
        $0.clipsToBounds = true
        $0.register(DashboardStatusCell.self, forCellWithReuseIdentifier: "DashboardStatusCell")
        $0.register(DashboardPieChartCell.self, forCellWithReuseIdentifier: "DashboardPieChartCell")
    }
    
    private let dataSource: [MySection] = [
        .first([
            MySection.FirstItem(value: "첫 레이아웃"),
        ]),
        .second([
            MySection.SecondItem(value: "두 번째 레이아웃"),
        ])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        selectedDate = Date()
        updateSelectedDateFormat()
        setupDateLabel()
        setupArrowButtons()
        setupCollectionView()
    }
    
    private func setupDateLabel() {
        view.addSubview(dateLabel)
        dateLabel.snp.makeConstraints{ make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }
    
    private func setupArrowButtons() {
        view.addSubview(previousButton)
        view.addSubview(nextButton)
        previousButton.snp.makeConstraints{ make in
            make.top.equalToSuperview()
            make.trailing.equalTo(dateLabel.snp.leading).offset(-10)
        }
        nextButton.snp.makeConstraints{ make in
            make.top.equalToSuperview()
            make.leading.equalTo(dateLabel.snp.trailing).offset(10)
        }
    }
    
    private func getLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { (section, _) -> NSCollectionLayoutSection? in
            
            func makeItem() -> NSCollectionLayoutItem {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let itemInset: CGFloat = 3.0
                item.contentInsets = NSDirectionalEdgeInsets(top: itemInset, leading: itemInset, bottom: itemInset, trailing: itemInset)
                item.contentInsets.leading = 15
                item.contentInsets.trailing = 15
                item.contentInsets.top = 15
                
                return item
            }
            
            func makeGroup(heightFraction: CGFloat) -> NSCollectionLayoutGroup {
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalHeight(heightFraction)
                )
                return NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [makeItem()])
            }
            
            switch section {
            case 0:
                return NSCollectionLayoutSection(group: makeGroup(heightFraction: 1.0 / 3.0))
            default:
                return NSCollectionLayoutSection(group: makeGroup(heightFraction: 1.0 / 2.0))
            }
        }
    }
    
    private func setupCollectionView () {
        view.addSubview(collectionView)
        collectionView.backgroundColor = .white
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom)
        }
        self.collectionView.dataSource = self
    }
    
    private func updateSelectedDateFormat() {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM월 dd일"
        
        if let weekInterval = calendar.dateInterval(of: .weekOfMonth, for: selectedDate) {
            let startDate = weekInterval.start
            let endDate = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? weekInterval.end
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            
            dateLabel.text = "\(startDateString) - \(endDateString)"
        }
    }
    
    @objc private func goToNextWeek() {
        guard let nextDay = calendar.date(byAdding: .day, value: 7, to: selectedDate) else {
            return
        }
        let currentDate = Date()
        if nextDay <= currentDate {
            selectedDate = nextDay
            updateSelectedDateFormat()
            delegate?.dateArrowButtonDidTap(data: selectedDate)
            dashboardStatusCell.dateArrowButtonDidTap(data: selectedDate)
            dashboardPieChartCell.dateArrowButtonDidTap(data: selectedDate)
            self.collectionView.reloadData()
        }
    }
    
    @objc private func goToPreviousWeek() {
        if let previousDay = calendar.date(byAdding: .day, value: -7, to: selectedDate) {
            selectedDate = previousDay
            updateSelectedDateFormat()
            delegate?.dateArrowButtonDidTap(data: selectedDate)
            dashboardStatusCell.dateArrowButtonDidTap(data: selectedDate)
            dashboardPieChartCell.dateArrowButtonDidTap(data: selectedDate)
            self.collectionView.reloadData()
        }
    }
}

extension WeekViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.dataSource.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.dataSource[section] {
        case let .first(items):
            return items.count
        case let .second(items):
            return items.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch self.dataSource[indexPath.section] {
        case .first(_):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardStatusCell", for: indexPath) as? DashboardStatusCell else {
                return UICollectionViewCell()
            }
            cell.updateUI(for: selectedDate, isWeek: true)
            
            return cell
        case .second(_):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardPieChartCell", for: indexPath) as? DashboardPieChartCell else {
                return UICollectionViewCell()
            }
            cell.setPieChartData(for: selectedDate)
            return cell
        }
    }
}


