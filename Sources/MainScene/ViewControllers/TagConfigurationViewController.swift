//
//  TagConfigurationViewController.swift
//  Pomodoro
//
//  Created by SonSinghae on 2024/02/15.
//

import PomodoroDesignSystem
import SnapKit
import Then
import UIKit
import Realm
import RealmSwift

final class TagConfigurationViewController: UIViewController, UITextFieldDelegate {
    // TODO: Realm Tag write
    private let database = DatabaseManager.shared
    
    private var selectedColorIndex: String?
    private var selectedPosition: Int?


    // MARK: 태그명 레이블
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "태그명"
        label.font = .pomodoroFont.heading5()
        label.textAlignment = .left
        return label
    }()

    private let paletteTitleLabel = UILabel().then { label in
        label.text = "태그 색상"
        label.font = .pomodoroFont.heading5()
        label.textAlignment = .left
    }

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.returnKeyType = .done
        textField.placeholder = "ex. 공부"
        textField.font = .pomodoroFont.heading6()
        textField.delegate = self
        textField.textAlignment = .left
        let bottomLine = UIView()
        bottomLine.backgroundColor = .black
        textField.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.bottom.equalTo(textField.snp.bottom).offset(10)
            make.left.right.equalTo(textField)
            make.height.equalTo(2)
        }
        return textField
    }()

    private lazy var createTagConfirmButton = PomodoroConfirmButton(title: "태그 생성",
                                                                    didTapHandler: saveTagButtonTapped)

    private let colorPaletteStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .equalSpacing
        $0.spacing = 8
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

    weak var delegate: TagCreationDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pomodoro.background
        navigationController?.isNavigationBarHidden = false
        setupViews()
        setupConstraints()
        setupColorPalette()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    @objc private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
    @objc func saveTagButtonTapped() {
        let tags = database.write(Tag())

        guard let tagText = textField.text, !tagText.isEmpty else {
            print("태그를 입력하세요.")
            PomodoroPopupBuilder()
                .add(body: "태그를 입력해주십시오.")
                .add(
                    button: .confirm(
                        title: "확인",
                        action: { /* 확인 동작 */
                            self.database.write(Tag(tagName: self.textField.text!, colorIndex: "one", position: 1))
                        }
                    )
                )
                .show(on: self)
            return
        }
        delegate?.createTag(tag: tagText)
        print("->>>>> ", tagText)
        database.write(Tag(tagName: tagText, colorIndex: "four", position: 1))
        dismiss(animated: true, completion: nil)
    }

    

    private func setupViews() {
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        let contentView = UIView().then {
            $0.backgroundColor = .pomodoro.background
            $0.layer.cornerRadius = 20
            $0.addSubview(titleView)
            $0.addSubview(closeButton)
            $0.addSubview(titleLabel)
            $0.addSubview(textField)
            $0.addSubview(paletteTitleLabel)
            $0.addSubview(createTagConfirmButton)
            $0.addSubview(colorPaletteStackView)
        }
        dimmedView.addSubview(contentView)
        view.addSubview(dimmedView)
        contentView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(view.frame.height * 0.8)
        }
    }

    private func setupConstraints() {
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

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(59)
            make.left.equalToSuperview().inset(40)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(40)
        }

        paletteTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(52)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        colorPaletteStackView.snp.makeConstraints { make in
            make.top.equalTo(paletteTitleLabel.snp.bottom).offset(34)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(150)
        }

        createTagConfirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(110)
            make.top.equalTo(colorPaletteStackView.snp.bottom).offset(66)
            make.height.equalTo(60)
        }
    }

    private func setupColorPalette() {
        let colors: [UIColor] = [
            .pomodoro.tagBackground1,
            .pomodoro.tagBackground2,
            .pomodoro.tagBackground3,
            .pomodoro.tagBackground4,
            .pomodoro.tagBackground5,
            .pomodoro.tagBackground6,
            .pomodoro.tagBackground7,
            .pomodoro.blackMedium,
        ]
        // colorPaletteStackView 설정
        colorPaletteStackView.axis = .vertical
        colorPaletteStackView.distribution = .fillEqually
        colorPaletteStackView.spacing = 20
        // 2행 4열
        let rows = [UIStackView(), UIStackView()]
        for row in rows {
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 15
            colorPaletteStackView.addArrangedSubview(row)
        }

        // 각 행에 색상 버튼 추가
        for (index, color) in colors.enumerated() {
            let colorButton = UIButton().then {
                $0.backgroundColor = color
                $0.layer.cornerRadius = 33
                $0.snp.makeConstraints { make in
                    make.size.equalTo(CGSize(width: 55, height: 55))
                }
                $0.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
                $0.tag = index  // 각 버튼에 태그 설정
                print("tag:/(index)")
            }
            // 적절한 행에 버튼 추가
            if index < 4 {
                rows[0].addArrangedSubview(colorButton)
            } else {
                rows[1].addArrangedSubview(colorButton)
            }
        }
    }

    // TODO: color 버튼 클릭시 정보 전달 로직, 화면상 나타나는 표시(컬러 변경이 더 쉬울 것 같음)
//    @objc private func colorButtonTapped(_ sender: UIButton) {
//        self.selectedColorIndex = sender.tag
//    }
    
    // 인덱스를 string으로 변환
    func indexToString(_ index: Int) -> String {
        switch index {
        case 0:
            return "one"
        case 1:
            return "two"
        case 2:
            return "three"
        case 3:
            return "four"
        case 4:
            return "five"
        case 5:
            return "six"
        case 6:
            return "seven"
        case 7:
            return "eight"
        default:
            return "unknown"
        }
    }

    @objc private func colorButtonTapped(_ sender: UIButton) {
        let index = sender.tag // 버튼의 태그로부터 인덱스 얻기
        let colorString = indexToString(index) // 인덱스를 문자열로 변환
        self.selectedColorIndex = colorString // 변환 문자열을 저장
        self.selectedPosition = index
    }

}

extension TagConfigurationViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
