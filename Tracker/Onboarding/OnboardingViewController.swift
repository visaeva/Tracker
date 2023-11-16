//
//  OnboardingViewController.swift
//  Tracker
//
//  Created by Victoria Isaeva on 25.10.2023.
//

import UIKit

final class OnboardingViewConttoller: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    lazy var pages: [UIViewController] = {
        let blue = UIViewController()
        let blueImageView = UIImageView(image: UIImage(named: "OnboardingBlue"))
        blueImageView.contentMode = .scaleAspectFill
        blue.view.addSubview(blueImageView)
        setupImageConstraints(imageView: blueImageView, in: blue)
        
        let red = UIViewController()
        let redImageView = UIImageView(image: UIImage(named: "OnboardingRed"))
        red.view.addSubview(redImageView)
        redImageView.contentMode = .scaleAspectFill
        setupImageConstraints(imageView: redImageView, in: red)
        
        return [blue, red]
    } ()
    
    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = .gray
        return pageControl
    }()
    
    private let titleBlueLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 2
        titleLabel.text = "Отслеживайте только\n то, что хотите"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        return titleLabel
    }()
    
    private let titleRedLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 2
        titleLabel.text = "Даже если это\n не литры воды и йога"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        return titleLabel
    }()
    
    let customButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black
        button.setTitle("Вот это технологии!", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(customButtonTapped), for: .touchUpInside)
        return button
    }()
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
        
        onboardingConstraints()
    }
    
    private func setupImageConstraints(imageView: UIImageView, in container: UIViewController) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
        ])
    }
    
    private func onboardingConstraints() {
        view.addSubview(titleBlueLabel)
        view.addSubview(pageControl)
        view.addSubview(customButton)
        view.addSubview(titleRedLabel
        )
        titleBlueLabel.translatesAutoresizingMaskIntoConstraints = false
        titleRedLabel.translatesAutoresizingMaskIntoConstraints = false
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleBlueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleBlueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleBlueLabel.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -130),
            
            titleRedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleRedLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleRedLabel.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -130),
            
            customButton.widthAnchor.constraint(equalToConstant: 335),
            customButton.heightAnchor.constraint(equalToConstant: 60),
            customButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -103),
            
            pageControl.centerXAnchor.constraint(equalTo: customButton.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: customButton.topAnchor, constant: -24),
        ])
        showLabelAtIndex(pageControl.currentPage)
    }
    
    private func showLabelAtIndex(_ index: Int) {
        
        if index == 0 {
            titleBlueLabel.isHidden = false
            titleRedLabel.isHidden = true
        } else if index == 1 {
            titleBlueLabel.isHidden = true
            titleRedLabel.isHidden = false
        }
    }
    
    @objc private func customButtonTapped() {
        let tabBarController = TabBarViewController()
        
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = tabBarController
            }, completion: nil)
            UserDefaults.standard.set(true, forKey: "onboardingShow")
        }
    }
    
    
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < pages.count else {
            return nil
        }
        
        return pages[nextIndex]
    }
    // MARK: - UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
            //   showLabelAtIndex(currentIndex)
        }
    }
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let nextIndex = pages.firstIndex(of: pendingViewControllers.first!) {
            showLabelAtIndex(nextIndex)
        }
    }
}



