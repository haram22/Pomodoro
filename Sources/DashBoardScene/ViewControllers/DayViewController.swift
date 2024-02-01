//
//  DashBoardTabView.swift
//  Pomodoro
//
//  Created by 김하람 on 2023/11/13.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import UIKit
import SnapKit

protocol DayViewControllerDelegate {
    func dateArrowButtonDidTap(data: Date)
}

final class DayViewController: UIViewController {
    private var delegate : DayViewControllerDelegate?
    private let dashboardStatusCell = DashboardStatusCell()
    private let dashboardPieChartCell = DashboardPieChartCell()
    private var selectedDate = Date()
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter().then {
        $0.dateStyle = .long
        $0.dateFormat = "MM월-dd일 오늘"
    }
    
    private lazy var dateLabel = UILabel().then {
        $0.text = dateFormatter.string(from: selectedDate)
        $0.textAlignment = .center
        $0.textColor = .black
    }
    
    private lazy var previousButton = UIButton().then {
        $0.setImage(UIImage(systemName: "arrowtriangle.backward")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        $0.addTarget(self, action: #selector(goToPreviousDay), for: .touchUpInside)
    }
    
    private lazy var nextButton = UIButton().then {
        $0.setImage(UIImage(systemName: "arrowtriangle.right")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        $0.addTarget(self, action: #selector(goToNextDay), for: .touchUpInside)
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
        let currentDate = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        if components.year == targetComponents.year &&
            components.month == targetComponents.month &&
            components.day == targetComponents.day {
            dateFormatter.dateFormat = "MM월 dd일, 오늘"
        } else {
            dateFormatter.dateFormat = "MM월 dd일"
        }
        dateLabel.text = dateFormatter.string(from: selectedDate)
    }
    
    @objc private func goToNextDay() {
        let currentDate = Date()
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) else {
            return
        }
        if nextDay <= currentDate {
            selectedDate = nextDay
            updateSelectedDateFormat()
            delegate?.dateArrowButtonDidTap(data: selectedDate)
        } else{
            return
        }
        dashboardStatusCell.dateArrowButtonDidTap(data: selectedDate)
        dashboardPieChartCell.dateArrowButtonDidTap(data: selectedDate)
        self.collectionView.reloadData()
    }
    
    @objc private func goToPreviousDay() {
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = previousDay
            updateSelectedDateFormat()
            delegate?.dateArrowButtonDidTap(data: selectedDate)
        }
        dashboardStatusCell.dateArrowButtonDidTap(data: selectedDate)
        dashboardPieChartCell.dateArrowButtonDidTap(data: selectedDate)
        self.collectionView.reloadData()
    }
}
//MARK: - UICollectionViewDataSource
extension DayViewController: UICollectionViewDataSource {
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
            cell.updateUI(for: selectedDate, isWeek: false)
            
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

enum MySection {
    case first([FirstItem])
    case second([SecondItem])
    
    struct FirstItem {
        let value: String
    }
    struct SecondItem {
        let value: String
    }
}
