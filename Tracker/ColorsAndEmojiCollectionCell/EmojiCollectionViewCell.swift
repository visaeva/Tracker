//
//  EmojiCollectionViewCell.swift
//  Tracker
//
//  Created by Victoria Isaeva on 02.09.2023.
//

import UIKit

final class EmojiCollectionViewCell: UICollectionViewCell {
    // MARK: - Public Properties
    let emojiLabel = UILabel()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
