//
//  ColorPaletteViewController.swift
//  Pomodoro
//
//  Created by SonSinghae on 2024/02/20.
//

import SnapKit
import Then
import UIKit

protocol ColorPaletteDelegate: AnyObject {
    func selectedColor(_ color: UIColor)
}

final class ColorPaletteViewController: UIViewController {
    weak var delegate: ColorPaletteDelegate?
    private var colors: [UIColor] = [
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple,
        .black,
        .white,
    ]
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        $0.collectionViewLayout = layout
        $0.delegate = self
        $0.dataSource = self
        $0.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "colorCell")
        $0.backgroundColor = .clear
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pomodoro.blackMedium
        setupCollectionView()
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension ColorPaletteViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        colors.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: indexPath)
        cell.backgroundColor = colors[indexPath.item]
        cell.layer.cornerRadius = 25
        cell.layer.masksToBounds = true
        return cell
    }

    // FIXME: 색상 클릭시 색상 데이터 전송
    func collectionView(
        _: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let selectedColor = colors[indexPath.item]
        delegate?.selectedColor(selectedColor)
        dismiss(animated: true, completion: nil)
    }
}
