//
//  TagModalViewController.swift
//  Pomodoro
//
//  Created by SonSinghae on 2023/11/17.
//  Copyright © 2023 io.hgu. All rights reserved.
//
import PomodoroDesignSystem
import Realm
import RealmSwift
import SnapKit
import Then
import UIKit

protocol TagCreationDelegate: AnyObject {
    func createTag(tag: String, color: String, position: Int)
}
// TODO: 2.태그 모달뷰에서 선택한 태그 값이 메인뷰에서 보이게 값 전달.
protocol TagModalViewControllerDelegate: AnyObject {
    func tagSelected(tagName: String, tagColor: String)
}

final class TagModalViewController: UIViewController {
    weak var selectionDelegate: TagModalViewControllerDelegate? // TODO: mainviewcontroller 에 태그 값들 전달

    private lazy var editTagButton = UIButton().then {
        $0.setTitle("Edit", for: .normal)
        $0.titleLabel?.font = .pomodoroFont.heading5()
        $0.setTitleColor(.pomodoro.blackHigh, for: .normal)
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .pomodoro.background
        $0.layer.cornerRadius = 15
        $0.clipsToBounds = true
        $0.addTarget(self, action: #selector(createMinusButton), for: .touchUpInside)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addTagsToStackView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        defaultTagLoad()
        setupViews()
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        tagSettingCompletedButton.isEnabled = false // 첫 화면에는 설정완료 비활성화
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

    private func defaultTagLoad() {
        guard let tagCount = try? RealmService.read(Tag.self).count, tagCount == 0 else { return }

        let defaultTags = [
            Tag(tagName: "공부", colorIndex: "one", position: 0),
            Tag(tagName: "수영", colorIndex: "two", position: 1),
            Tag(tagName: "독서", colorIndex: "three", position: 2)
        ]

        for tag in defaultTags {
            do {
                RealmService.write(tag)
                Log.info("Added tag: \(tag.tagName)")
            } catch {
                Log.info("Error preloading tag \(tag.tagName): \(error)")
            }
        }
    }

    private func addTagsToStackView() {
        tagsStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        let tagList = try? RealmService.read(Tag.self)
        Log.info("TAGLIST: \(String(describing: tagList))")
        let maxTags = 7
        let firstRow = makeRowStackView()
        let secondRow = makeRowStackView()
        let thirdRow = makeRowStackView()

        for item in 0 ... maxTags {
            let button: UIButton

            if let tagList, tagList.count > item {
                let title = tagList[item].tagName
                let index = tagList[item].colorIndex
                let position = tagList[item].position
                button = createRoundButton(title: title, colorIndex: index, tagIndex: position)
            } else {
                button = createEmptyButton(borderColor: .pomodoro.tagBackground1)
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

    private func createRoundButton(title: String, colorIndex: String, tagIndex: Int) -> UIButton {
        let backgroundColor = TagCase(rawValue: colorIndex)?.backgroundColor ?? .black
        let titleColor = TagCase(rawValue: colorIndex)?.typoColor ?? .black

        Log.info(TagCase(rawValue: colorIndex)?.typoColor ?? .black)
        Log.info("태그 인덱스: \(tagIndex)")
        let button = UIButton().then {
            $0.setTitle(title, for: .normal)
            $0.titleLabel?.font = .pomodoroFont.heading4()
            $0.backgroundColor = backgroundColor
            $0.setTitleColor(titleColor, for: .normal)
            $0.tag = tagIndex
            $0.layer.cornerRadius = 40
            $0.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 80, height: 80))
            }
        }
        // 버튼 액션 설정
        button.addAction(UIAction { [weak self] _ in
            self?.buttonTapped(tag: title, color: colorIndex)
        }, for: .touchUpInside)

        // MARK: `-` 버튼 추가 -> 이미지로 넣는 게 더 괜찮아보임.

        let minusButton = UIButton().then {
            $0.setTitle("-", for: .normal)
            $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20) // 볼드
            $0.setTitleColor(.gray, for: .normal)
            $0.backgroundColor = .white
            $0.layer.borderColor = UIColor.gray.cgColor
            $0.layer.borderWidth = 1
            $0.layer.cornerRadius = 10
            $0.isHidden = true // 기본적으로 숨김
            $0.tag = tagIndex
            Log.info("마이너스 버튼의 태그 인덱스: \(tagIndex)")
        }
        button.addSubview(minusButton)

        // MARK: minusButton 위치 설정

        minusButton.snp.makeConstraints { make in
            make.top.equalTo(button.snp.top).offset(5)
            make.right.equalTo(button.snp.right).offset(-5)
            make.width.height.equalTo(20) // 작은 버튼 크기
        }

        // MARK: minusButton에 삭제 액션 추가
        minusButton.addTarget(self, action: #selector(deletTag(sender:)), for: .touchUpInside)
        

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
    // TODO: 태그 값이 메인뷰에 전달하는 함수
      func selectTag(tagName: String, tagColor: String) {
          selectionDelegate?.tagSelected(tagName: tagName, tagColor: tagColor)
          dismiss(animated: true, completion: nil)
      }

    @objc private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func buttonTapped(tag: String, color: String) {
        if let tag = try? RealmService.read(Tag.self).filter("tagName == %@", tag).first {
            selectionDelegate?.tagSelected(tagName: tag.tagName, tagColor: tag.colorIndex)
            tagSettingCompletedButton.isEnabled.toggle()
        } else {
            presentTagEditViewController()
        }
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

    @objc private func deletTag(sender: UIButton) {
        let tagIndex = sender.tag
        print("Button with tag \(sender.tag) was clicked")
        PomodoroPopupBuilder()
            .add(title: "태그 삭제")
            .add(body: "태그를 정말 삭제하시겠습니까? 한 번 삭제한 태그는 다시 되돌릴 수 없습니다.")
            .add(button: .confirm(title: "확인", action: { [weak self] in
                guard let self = self else { return }
                do {
                    if let tagToDelete = try RealmService.read(Tag.self).filter("position == \(tagIndex)").first {
                        print("Tag at index \(tagIndex) deleted")
                        RealmService.delete(tagToDelete)
                    } else {
                        print("No tag found at index \(tagIndex)")
                    }
                } catch {
                    print("Error deleting tag: \(error)")
                }
            }))
            .show(on: self)
    }

    // TODO: Editbutton 클릭시 - 버튼 활성화 함수
    @objc private func createMinusButton() {
        tagSettingCompletedButton.isEnabled.toggle()  // 설정 완료 버튼의 활성화 상태 토글
        for case let button as UIButton in tagsStackView.arrangedSubviews.flatMap(\.subviews) {
            // 각 버튼의 서브뷰 중에서 UIButton 타입을 찾고, "-" 문자를 가진 버튼이면 minusButton
            if let minusButton = button.subviews.first(where: { subview in
                guard let btn = subview as? UIButton else { return false }
                return btn.title(for: .normal) == "-"
            }) as? UIButton {
                minusButton.isHidden.toggle()
                button.bringSubviewToFront(minusButton)
            }
        }
    }
}

// MARK: - TagCreationDelegate

extension TagModalViewController: TagCreationDelegate {
    func createTag(tag: String, color: String, position: Int) {
        RealmService.write(Tag(tagName: tag, colorIndex: color, position: position))
        Log.info("New tag created ==> Name: \(tag), Color Index: \(color), Position: \(position)")
    }
}
