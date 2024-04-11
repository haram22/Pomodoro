//
//  TagModalViewController.swift
//  Pomodoro
//
//  Created by SonSinghae on 2023/11/17.
//  Copyright © 2023 io.hgu. All rights reserved.
//
import PomodoroDesignSystem
import SnapKit
import Then
import UIKit
import Realm
import RealmSwift

protocol TagCreationDelegate: AnyObject {
    func createTag(tagName: String, colorIndex: String, position: Int)
}

protocol TagModalViewControllerDelegate: AnyObject {
    func tagSelected(tag: String)
}

final class TagModalViewController: UIViewController {
    // realm database
    let database = DatabaseManager.shared

    private weak var selectionDelegate: TagModalViewControllerDelegate?

    private lazy var editTagButton = UIButton().then {
        $0.setTitle("Edit", for: .normal)
        $0.titleLabel?.font = .pomodoroFont.heading5()
        $0.setTitleColor(.pomodoro.blackHigh, for: .normal)
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .pomodoro.background
        $0.layer.cornerRadius = 15
        $0.clipsToBounds = true
        $0.addTarget(self, action: #selector(createMinusButton), for: .touchUpInside) // 마이너스버튼 생성되는 액션 추가
    }

    private let tagsStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
        $0.alignment = .center
        $0.distribution = .equalSpacing
    }

    private let dimmedView = UIView().then {
        $0.backgroundColor = .pomodoro.blackHigh.withAlphaComponent(0.2)
    }

    private let titleView = UILabel().then {
        $0.text = "태그 설정"
        $0.font = .pomodoroFont.heading4()
    }

    private let closeButton = UIButton().then {
        $0.setImage(UIImage(named: "closeButton"), for: .normal)
    }

    private lazy var tagSettingCompletedButton = PomodoroConfirmButton(
        title: "설정 완료",
        didTapHandler: didTapSettingCompleteButton
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        addTagsToStackView()
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        tagSettingCompletedButton.isEnabled = false // 첫 화면에는 설정완료 비활성화
        database.getLocationOfDefaultRealm()
    }

    private func setupViews() {
        view.backgroundColor = .pomodoro.background
        view.addSubview(dimmedView)

        let contentView = UIView().then {
            $0.backgroundColor = .pomodoro.background
            $0.layer.cornerRadius = 20
        }
        dimmedView.addSubview(contentView)

        contentView.addSubview(closeButton)
        contentView.addSubview(titleView)
        contentView.addSubview(tagSettingCompletedButton)
        contentView.addSubview(tagsStackView)
        contentView.addSubview(tagSettingCompletedButton)

        contentView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(view.frame.height * 0.8)
        }

        closeButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(20)
        }

        titleView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(closeButton.snp.centerY)
        }

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.addSubview(editTagButton)
        editTagButton.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(20)
            make.trailing.equalTo(closeButton.snp.trailing)
        }
        tagsStackView.snp.makeConstraints { make in
            make.top.equalTo(editTagButton.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(45)
        }
        tagSettingCompletedButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(110)
            make.top.equalTo(tagsStackView.snp.bottom).offset(60)
            make.height.equalTo(60)
        }
    }

    private func makeRowStackView() -> UIStackView {
        UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 10
            $0.alignment = .fill
            $0.distribution = .fillEqually
        }
    }

    private func addTagsToStackView() {
        let buttonTitlesAndColors = [
            ("명상", UIColor.red),
            ("운동", UIColor.green),
            ("공부", UIColor.purple)
        ]
        
//        database.write(Tag(tagName: "집중", colorIndex: 0, position: 0))
//        database.write(Tag(tagName: "업무", colorIndex: 1, position: 1))
//        
        let maxTags = 7
        var currentIndex = 0
        let firstRow = makeRowStackView()
        let secondRow = makeRowStackView()
        let thirdRow = makeRowStackView()

        for item in 0 ... maxTags {
            let button: UIButton
            if (buttonTitlesAndColors.count - 1) < item {
                button = createEmptyButton(borderColor: .pomodoro.tagBackground1)
            } else {
                let (title, color) = buttonTitlesAndColors[item]
                button = createRoundButton(title: title, color: color)
            }
            switch item {
            case 0 ... 1:
                firstRow.addArrangedSubview(button)
            case 2 ... 4:
                secondRow.addArrangedSubview(button)
            case 5 ... 6:
                thirdRow.addArrangedSubview(button)
            default: 
                break
            }
        }

        tagsStackView.addArrangedSubview(firstRow)
        tagsStackView.addArrangedSubview(secondRow)
        tagsStackView.addArrangedSubview(thirdRow)
    }

    private func createRoundButton(title: String, color _: UIColor) -> UIButton {
        let button = UIButton().then {
            $0.setTitle(title, for: .normal)
            $0.titleLabel?.font = .pomodoroFont.heading4()
            $0.backgroundColor = .pomodoro.tagBackground1 // TODO: change color
            $0.setTitleColor(.pomodoro.tagTypo1, for: .normal) // TODO: change color
            $0.layer.cornerRadius = 40
            $0.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 80, height: 80))
            }
            $0.addTarget(self, action: #selector(presentTagEditViewController), for: .touchUpInside)
        }

        // MARK: `-` 버튼 추가
        let minusButton = UIButton().then {
            $0.setTitle("-", for: .normal)
            $0.setTitleColor(.black, for: .normal)
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 10
            $0.isHidden = true // 기본적으로 숨김
            $0.tag = 101 // 태그 설정
        }
        button.addSubview(minusButton)

        // MARK: minusButton 위치 설정

        minusButton.snp.makeConstraints { make in
            make.top.equalTo(button.snp.top).offset(5)
            make.right.equalTo(button.snp.right).offset(-5)
            make.width.height.equalTo(20) // 작은 버튼 크기
        }

        // MARK: minusButton에 삭제 액션 추가
        minusButton.addTarget(self, action: #selector(deletTag), for: .touchUpInside)

        return button
    }

    private func createEmptyButton(borderColor: UIColor) -> UIButton {
        UIButton().then {
            $0.titleLabel?.font = .pomodoroFont.heading4()
            $0.backgroundColor = .clear // TODO: change colo
            $0.layer.borderColor = borderColor.cgColor
            $0.layer.borderWidth = 1
            $0.layer.cornerRadius = 40
            $0.setImage(UIImage(named: "plusButton"), for: .normal)
            $0.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 80, height: 80))
            }
            $0.addTarget(self, action: #selector(presentTagEditViewController), for: .touchUpInside)
        }
    }


    @objc private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }

    @objc func presentTagEditViewController() {
        let configureTagViewController = TagConfigurationViewController()
        configureTagViewController.modalPresentationStyle = .fullScreen
        present(configureTagViewController, animated: true)
        tagSettingCompletedButton.isEnabled.toggle()
    }

    @objc private func didTapSettingCompleteButton() {
        tagSettingCompletedButton.isEnabled.toggle()
        PomodoroPopupBuilder()
        dismiss(animated: true)
    }

    // TODO: Tag 삭제 버튼 연결
    @objc private func deletTag() {
        tagSettingCompletedButton.isEnabled.toggle()
        PomodoroPopupBuilder()
            .add(title: "태그 삭제")
            .add(body: "태그를 정말 삭제하시겠습니까? 한 번 삭제한 태그는 다시 되돌릴 수 없습니다.")
            .add(
                button: .confirm(
                    title: "확인",
                    action: { [weak self] in
//                        guard let button = sender.superview as? UIButton else { return }
//                        button.setTitle("+", for: .normal)
                    }
                )
            )
            .show(on: self)
    }

    // TODO: Editbutton 클릭시 - 버튼 활성화 함수
    @objc private func createMinusButton() {
        tagSettingCompletedButton.isEnabled.toggle()
        for case let button as UIButton in tagsStackView.arrangedSubviews.flatMap(\.subviews) {
            if let minusButton = button.viewWithTag(101) as? UIButton {
                minusButton.isHidden.toggle()
                button.bringSubviewToFront(minusButton)
            }
        }
    }
}

// MARK: - TagCreationDelegate

//extension TagModalViewController: TagCreationDelegate {
//    func createTag(tagName: String, colorIndex: String, position: Int) {
//        // TODO: 추가된 태그 정보값 전달
//        let tags = DatabaseManager.shared.write(Tag(tagName: "공부", colorIndex: "one", position: 1)
//        )
//    }
//}
extension TagModalViewController: TagCreationDelegate {
    func createTag(tag: String) {
        TagCollectionViewData.data.append(tag)
        // TODO: 추가된 태그 정보값 전달
        database.write(Tag(tagName: tag, colorIndex: "one", position: 1))
        print("=====> ", tag)
    }
}
