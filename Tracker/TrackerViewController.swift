//
//  TrackerViewController.swift
//  Tracker
//
//  Created by Victoria Isaeva on 26.09.2023.
//

import UIKit

final class TrackerViewController: UIViewController {
    
    // MARK: - Public Properties
    var currentDate: Date = Date()
    
    // MARK: - Private Properties
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var trackersId = Set<UUID>()
    
    private var myCategories: [TrackerCategory] = [
        TrackerCategory(
            title: "Пойти в магазин",
            trackers: [ Tracker(
                id: UUID(),
                name: "Хлеб",
                color: .red,
                emoji: "🍔",
                mySchedule: [.monday, .friday]),
                        
                        Tracker(id: UUID(),
                                name: "Торт",
                                color: .blue,
                                emoji: "❤️",
                                mySchedule: [.tuesday])
            ]),
        TrackerCategory(
            title: "Убираться",
            trackers: [Tracker(
                id: UUID(),
                name: "Протереть пыль",
                color: .orange,
                emoji: "🙌",
                mySchedule: [.tuesday, .saturday])
            ])
    ]
    
    private lazy var addTrackerButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "plus")
        barButtonItem.action = #selector(addTrackerButtonTapped)
        barButtonItem.tintColor = .black
        barButtonItem.target = self
        return barButtonItem
    }()
    
    private var createDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.calendar = Calendar(identifier: .gregorian)
        datePicker.calendar.firstWeekday = 2
        return datePicker
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Поиск"
        searchController.searchBar.setValue("Отменить", forKey: "cancelButtonText")
        searchController.delegate = self
        return searchController
    }()
    
    private let trackerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    private lazy var pictureStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.isHidden = true
        return stackView
    }()
    
    private lazy var pictureImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.image = UIImage(named: "star")
        imageView.contentMode = .center
        return imageView
    }()
    
    private lazy var pictureText: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.text = "Что будем отслеживать?"
        return label
    }()
    
    // MARK: - View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        setupUI()
        setupConstraints()
        
        categories = myCategories
        pictureStackView.isHidden = !categories.isEmpty
        
        createDatePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        pictureStackView.addArrangedSubview(pictureImageView)
        pictureStackView.addArrangedSubview(pictureText)
        
        view.addSubview(pictureStackView)
        view.addSubview(trackerCollectionView)
        view.bringSubviewToFront(pictureStackView)
        
        trackerCollectionView.delegate = self
        trackerCollectionView.dataSource = self
        trackerCollectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.cellID)
        trackerCollectionView.register(TrackerHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrackerHeader.header)
        trackerCollectionView.showsVerticalScrollIndicator = false
        trackerCollectionView.showsHorizontalScrollIndicator = false
        
        navigationItem.title = "Трекеры"
        navigationItem.searchController = searchController
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationController?.navigationBar.topItem?.leftBarButtonItem = addTrackerButton
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(customView: createDatePicker)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            pictureStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            pictureStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            trackerCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            trackerCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            trackerCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            trackerCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func filterDataByDate() {
        let calendar = Calendar.current
        let filterWeekDay = (calendar.component(.weekday, from: currentDate) + 5) % 7
        filterData { tracker in
            tracker.mySchedule.isEmpty || tracker.mySchedule.contains { weekDay in
                return weekDay.rawValue == filterWeekDay
            }
        }
    }
    
    private func filterData(filteringСondition:(Tracker)->(Bool)) {
        categories = myCategories.map { trackerCategory in
            TrackerCategory(title: trackerCategory.title,
                            trackers: trackerCategory.trackers.filter { filteringСondition($0) })
        }.filter { $0.trackers.count > 0 }
        pictureStackView.isHidden = !categories.isEmpty
    }
    
    private func filters() {
        if let filterText = searchController.searchBar.searchTextField.text?.lowercased(), filterText.count > 0 {
            filterData { tracker in
                tracker.name.lowercased().hasPrefix(filterText)
            }
        } else {
            filterDataByDate()
        }
        trackerCollectionView.reloadData()
    }
    
    @objc private func datePickerChanged(sender: UIDatePicker) {
        currentDate = createDatePicker.date
        filters()
    }
    
    @objc private func addTrackerButtonTapped() {
        trackerCollectionView.reloadData()
        let trackerCreator = TrackerCreatorViewController(delegate: self)
        trackerCreator.delegate = self
        trackerCreator.myCategories = myCategories
        let navigationController = UINavigationController(rootViewController: trackerCreator)
        present(navigationController, animated: true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: TrackerCreatirDelegate
extension TrackerViewController: TrackerCreatorDelegate {
    func newTrackerCreated(_ tracker: Tracker) {
        let newCategory = TrackerCategory(title: "Новая категория", trackers: [tracker])
        myCategories.append(newCategory)
        filters()
        trackerCollectionView.reloadData()
        dismiss(animated: true, completion: nil)
    }
    
    func didSelectTrackerType(_ type: String) {
    }
}

// MARK: UICollectionViewDataSource
extension TrackerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.cellID, for: indexPath) as? TrackerCell
        else {
            return UICollectionViewCell()
        }
        let tracker = categories[indexPath.section].trackers[indexPath.row]
        let resCompare = Calendar.current.compare(Date(), to: currentDate, toGranularity: .day)
        
        let model = TrackerCellViewModel(name: tracker.name,
                                         emoji: tracker.emoji,
                                         color: tracker.color,
                                         trackerIsDone: trackersId.contains(tracker.id),
                                         doneButtonIsEnabled: resCompare == .orderedSame || resCompare == .orderedDescending,
                                         counter: trackersId.contains(tracker.id) ? 1 : 0,
                                         id: tracker.id)
        cell.configure(model: model)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrackerHeader.header, for: indexPath) as? TrackerHeader
        else {
            return UICollectionReusableView()
        }
        view.configure(headerText: categories[indexPath.section].title)
        return view
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension TrackerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - 9) / 2, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
}

// MARK: TrackerCellDelegate
extension TrackerViewController: TrackerCellDelegate {
    
    func trackerCellDelegate(id: UUID) {
        trackersId.contains(id) ? removeExecutionTracker(id: id) : addExecutionTracker(id: id)
    }
    
    private func addExecutionTracker(id: UUID) {
        let recordTracker = TrackerRecord(id: id, date: currentDate)
        completedTrackers.append(recordTracker)
        trackersId.insert(id)
        trackerCollectionView.reloadData()
    }
    
    private func removeExecutionTracker(id: UUID) {
        completedTrackers.removeAll { $0.id == id && $0.date == currentDate}
        trackersId.remove(id)
        trackerCollectionView.reloadData()
    }
}

// MARK: UISearchResultsUpdating
extension TrackerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filters()
    }
}

// MARK: UISearchControllerDelegate
extension TrackerViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        filterDataByDate()
    }
}

// MARK: NewHabitViewControllerDelegate
extension TrackerViewController: NewHabitViewControllerDelegate {
    func didAddNewTracker(_ newTracker: Tracker) {
        trackerCollectionView.reloadData()
    }
}
