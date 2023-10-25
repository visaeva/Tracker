//
//  ColorsCollectionViewCell.swift
//  Tracker
//
//  Created by Victoria Isaeva on 01.10.2023.
//

import UIKit

class ColorsCollectionViewCell: UICollectionViewCell {
    // MARK: - Public Properties
    let colorLabel = UILabel()
    let colorImageView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                let selectedBackgroundView = UIView()
                selectedBackgroundView.backgroundColor = .clear
                selectedBackgroundView.layer.cornerRadius = 8
                selectedBackgroundView.layer.borderWidth = 3
                let borderColor = colorImageView.backgroundColor?.withAlphaComponent(0.3).cgColor
                selectedBackgroundView.layer.borderColor = borderColor
                self.selectedBackgroundView = selectedBackgroundView
            } else {
                self.selectedBackgroundView = nil
            }
        }
    }
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(colorLabel)
        contentView.addSubview(colorImageView)
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        colorImageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.layer.borderColor = nil
        
        NSLayoutConstraint.activate([
            colorImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorImageView.heightAnchor.constraint(equalToConstant: 40),
            colorImageView.widthAnchor.constraint(equalToConstant: 40)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

