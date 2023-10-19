//
//  TrackerHeader.swift
//  Tracker
//
//  Created by Victoria Isaeva on 26.09.2023.
//

import UIKit

final class TrackerHeader: UICollectionReusableView {
    
    // MARK: - Public Properties
    static var header = "header"
    
    // MARK: - Private Properties
    private var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        return label
    }()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabelViews()
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        super.init(coder: coder)
    }
    
    // MARK: - Public Methods
    func configure(headerText: String) {
        headerLabel.text = headerText
    }
    
    // MARK: - Private Methods
    private func setupLabelViews() {
        addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
}
