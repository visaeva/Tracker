//
//  Colors.swift
//  Tracker
//
//  Created by Victoria Isaeva on 26.11.2023.
//

import UIKit

final class Colors {
    let viewBackgroundColor = UIColor.mainColor
    var navigationBarTintColor = UIColor.mainColor
    var tabBarBackgroundColor = UIColor.mainColor
    var collectionViewBackgroundColor = UIColor.mainColor
    
    var labelTextColor: UIColor = UIColor { (traits) -> UIColor in
        let isDarkMode = traits.userInterfaceStyle == .dark
        return isDarkMode ? UIColor.white : UIColor.black
    }
    
    var buttonTextColor: UIColor = UIColor { (traits) -> UIColor in
        let isDarkMode = traits.userInterfaceStyle == .dark
        return isDarkMode ? UIColor.black : UIColor.white
    }
    
    static var backgroundLight = UIColor { (traits) -> UIColor in
        let isDarkMode = traits.userInterfaceStyle == .dark
        return isDarkMode ? UIColor.white: UIColor.white
    }
    
    func searchTextFieldColor() -> UIColor {
        return UIColor { (traits) -> UIColor in
            let isDarkMode = traits.userInterfaceStyle == .dark
            return isDarkMode ? UIColor.white : UIColor.gray
        }
    }
    
    func searchControllerTextFieldPlaceholderAttributes() -> [NSAttributedString.Key: Any] {
        return [
            .foregroundColor: searchTextFieldColor(),
        ]
    }
    
    var filterViewBackgroundColor: UIColor {
        return UIColor { (traits) -> UIColor in
            let isDarkMode = traits.userInterfaceStyle == .dark
            return isDarkMode ? UIColor.backgroundDark : UIColor.darkBackground
        }
    }
}
