//
//  TrackerViewController.swift
//  Tracker
//
//  Created by Victoria Isaeva on 26.09.2023.
//

import UIKit

protocol TrackerViewControllerDelegate: AnyObject {
    func createTracker(_ tracker: Tracker?, titleCategory: String?)
}

final class TrackerViewController: UIViewController {
    
    // MARK: - Public Properties
    var currentDate: Date = Date()
    var trackerCategoryMap: [UUID: Int] = [:]
    
    // MARK: - Private Properties
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var visibleCategories: [TrackerCategory] = []
    private let trackerStore = TrackerStore()
    private let trackerRecordStore = TrackerRecordStore()
    private let trackerCategoryStore = TrackerCategoryStore()
    private var trackersId = Set<UUID>()
    private var currentFilter: String = LocalizableStringKeys.allTrackers
    private let colors = Colors()
    private let analiticsService = AnalyticsService()
    
    private lazy var addTrackerButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "plus")
        barButtonItem.tintColor = colors.labelTextColor
        barButtonItem.action = #selector(addTrackerButtonTapped)
        barButtonItem.target = self
        return barButtonItem
    }()
    
    private var createDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.subviews[0].backgroundColor = Colors.backgroundLight
        datePicker.subviews[0].layer.cornerRadius = 8
        
        datePicker.overrideUserInterfaceStyle = .light
        let currentLocale = Locale.current
        let calendar = Calendar(identifier: .gregorian)
        
        if currentLocale.languageCode == "ru" {
            datePicker.locale = Locale(identifier: "ru_RU")
            datePicker.calendar = calendar
            datePicker.calendar.firstWeekday = 2
        } else {
            datePicker.calendar = calendar
            datePicker.calendar.firstWeekday = 1
        }
        
        return datePicker
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: LocalizableStringKeys.searchBar, attributes: Colors().searchControllerTextFieldPlaceholderAttributes())
        searchController.searchBar.setValue(LocalizableStringKeys.searchBarCancel, forKey: "cancelButtonText")
        searchController.delegate = self
        return searchController
    }()
    
    private let trackerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
        label.textColor = colors.labelTextColor
        label.text = LocalizableStringKeys.pictureText
        return label
    }()
    
    private lazy var pictureSearchView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.isHidden = true
        return stackView
    }()
    
    private lazy var searchPicture: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.image = UIImage(named: "nothing")
        imageView.contentMode = .center
        return imageView
    }()
    
    private lazy var searchText: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = colors.labelTextColor
        label.text = LocalizableStringKeys.nothingFound
        return label
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(LocalizableStringKeys.filters, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = colors.viewBackgroundColor
        setupUI()
        setupConstraints()
        
        trackerStore.delegate = self
        updateCompletedTrackers()
        trackerCollectionView.reloadData()
        filterDataByDate()
        createDatePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        updateFilterButtonVisibility()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analiticsService.report(event: "open", params: ["screen": "Main"])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        analiticsService.report(event: "close", params: ["screen": "Main"])
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        pictureStackView.addArrangedSubview(pictureImageView)
        pictureStackView.addArrangedSubview(pictureText)
        pictureSearchView.addArrangedSubview(searchPicture)
        pictureSearchView.addArrangedSubview(searchText)
        
        view.addSubview(trackerCollectionView)
        view.addSubview(pictureStackView)
        view.addSubview(pictureSearchView)
        view.addSubview(filterButton)
        
        trackerCollectionView.delegate = self
        trackerCollectionView.dataSource = self
        trackerCollectionView.backgroundColor = colors.collectionViewBackgroundColor
        trackerCollectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.cellID)
        trackerCollectionView.register(TrackerHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrackerHeader.header)
        trackerCollectionView.showsVerticalScrollIndicator = false
        trackerCollectionView.showsHorizontalScrollIndicator = false
        
        navigationController?.navigationBar.barTintColor = colors.navigationBarTintColor
        navigationItem.title = LocalizableStringKeys.tabBarTrackers
        navigationItem.searchController = searchController
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationController?.navigationBar.topItem?.leftBarButtonItem = addTrackerButton
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(customView: createDatePicker)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            pictureStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            pictureStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            pictureSearchView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            pictureSearchView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            trackerCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            trackerCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            trackerCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            trackerCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50),
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        trackerCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 66, right: 0)
        trackerCollectionView.scrollIndicatorInsets = trackerCollectionView.contentInset
    }
    
    private func placeholderForAllTrackers() {
        let isHidden = trackerStore.numberOfSections() == 0 && searchController.searchBar.searchTextField.text != ""
        pictureSearchView.isHidden = !isHidden
        if pictureStackView.isHidden == false {
            pictureSearchView.isHidden = true
        }
        updateFilterButtonVisibility()
        trackerCollectionView.reloadData()
    }
    
    private func updateFilterButtonVisibility() {
        let shouldShowFilterButton = trackerStore.numberOfSections() > 0
        filterButton.isHidden = !shouldShowFilterButton
        trackerCollectionView.reloadData()
    }
    
    private func placeholderForOtherTrackers() {
        if trackerStore.numberOfSections() > 0 && trackerStore.numberOfRows(at: 0) > 0 {
            pictureSearchView.isHidden = true
            pictureStackView.isHidden = true
        } else {
            pictureSearchView.isHidden = false
            pictureStackView.isHidden = true
        }
        filterButton.isHidden = !areFiltersApplied
        
        trackerCollectionView.reloadData()
    }
    
    private func filterDataByDate() {
        let calendar = Calendar.current
        currentDate = createDatePicker.date
        trackerStore.updateDayOfWeekPredicate(for: currentDate)
        trackerStore.applyPredicate()
        if trackerStore.numberOfSections() == 0 {
            pictureStackView.isHidden = false
        } else {
            pictureStackView.isHidden = true
        }
        trackerCollectionView.reloadData()
    }
    
    private func filterData(filteringСondition:(Tracker)->(Bool)) {
        visibleCategories = categories.map { trackerCategory in
            TrackerCategory(title: trackerCategory.title,
                            trackers: trackerCategory.trackers.filter { filteringСondition($0) })}.filter {
                $0.trackers.count > 0 }
    }
    
    private func filters() {
        if let filterText = searchController.searchBar.searchTextField.text?.lowercased(), filterText.count > 0 {
            trackerStore.updateNameFilter(nameFilter: filterText)
            pictureSearchView.isHidden = trackerStore.numberOfSections() > 0 && trackerStore.numberOfRows(at: 0) > 0
            pictureStackView.isHidden = true
        } else {
            trackerStore.updateNameFilter(nameFilter: nil)
            filterDataByDate()
            pictureSearchView.isHidden = true
        }
        trackerCollectionView.reloadData()
    }
    
    private func applyFilters() {
        filters()
        
        switch  currentFilter {
        case "Все трекеры":
            placeholderForAllTrackers()
            break
            
        case "Трекеры на сегодня":
            placeholderForOtherTrackers()
            createDatePicker.date = Date().deleteTime() ?? Date()
            trackerStore.filterForToday()
            filterDataByDate()
            FilterViewController.selectedFilterIndex = 0
            currentFilter = LocalizableStringKeys.allTrackers
            
        case "Завершенные":
            placeholderForOtherTrackers()
            trackerStore.filterCompleted(for: createDatePicker.date.deleteTime() ?? Date())
            
        case "Не завершенные":
            placeholderForOtherTrackers()
            trackerStore.filterNotCompleted(for: createDatePicker.date.deleteTime() ?? Date())
        default:
            break
        }
        trackerCollectionView.reloadData()
    }
    
    var areFiltersApplied: Bool {
        switch currentFilter {
        case "Все трекеры", "Трекеры на сегодня", "Завершенные", "Не завершенные":
            return true
        default:
            return false
        }
    }
    
    private func updateCompletedTrackers() {
        if let completedTrackers = trackerRecordStore.trackerRecords {
            self.completedTrackers = completedTrackers
        } else {
            self.completedTrackers = []
        }
    }
    
    private func createCustomActions(id: UUID) -> [UIAction] {
        
        guard let tracker = trackerStore.getTracker(with: id) else {
            return []
        }
        let isPinned = isTrackerPinned(tracker)
        let pinActionTitle = isPinned ? "Открепить" : "Закрепить"
        let pinAction = UIAction(
            title: pinActionTitle,
            image: nil,
            identifier: nil,
            discoverabilityTitle: nil,
            state: .off) { [weak self] action in
                guard let self else { return }
                self.trackerStore.setIsPinned(for: tracker)
                self.trackerCollectionView.reloadData()
            }
        
        let editAction = UIAction(title: LocalizableStringKeys.edit) { [ weak self ] _ in
            if tracker.isPinned {
                if let trackerCategory = self?.trackerCategoryStore.getCategoryTitleByTrackerID(id) {
                    self?.editTracker(id, category: trackerCategory)
                }
            } else {
                if let mainCategory = self?.trackerStore.getMainCategoryByTrackerID(id) {
                    self?.editTracker(id, category: mainCategory)
                }
            }
            self?.analiticsService.report(event: "click", params: ["screen": "Main", "item": "edit"])
        }
        
        let deleteAction = UIAction(title: LocalizableStringKeys.delete, image: nil, attributes: .destructive) { [ weak self ] _ in
            guard let self else { return }
            self.showDeleteConfirmation(id: id)
            self.analiticsService.report(event: "click", params: ["screen": "Main", "item": "delete"])
        }
        
        return [pinAction, editAction, deleteAction]
    }
    
    private func showDeleteConfirmation(id: UUID) {
        let alertController = UIAlertController(
            title: LocalizableStringKeys.sureToDelete,
            message: nil,
            preferredStyle: .actionSheet
        )
        let deleteAction = UIAlertAction(title: LocalizableStringKeys.delete, style: .destructive) { [weak self] _ in
            self?.deleteTracker(id)
        }
        let cancelAction = UIAlertAction(title: LocalizableStringKeys.cancel, style: .cancel, handler: nil)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func deleteTracker(_ id: UUID) {
        trackerStore.deleteTracker(with: id)
        didUpdate()
        trackerCollectionView.reloadData()
    }
    
    private func editTracker(_ id: UUID, category: String?) {
        if let tracker = trackerStore.getTracker(with: id) {
            var recordsString = ""
            if let trackerRecords = trackerRecordStore.trackerRecords {
                let numberOfDays = trackerRecords
                    .filter { $0.id == id }
                    .count
                recordsString = String.localizedStringWithFormat(
                    NSLocalizedString("numberOfTasks", comment: ""),
                    numberOfDays)
            }
            let viewController: UIViewController
            if Set(WeekDay.allCases).isSubset(of: tracker.mySchedule) {
                let newEventVC = NewEventViewController(tracker: tracker, category: category)
                newEventVC.recordsLabel.text = recordsString
                newEventVC.updateUIForCurrentMode()
                viewController = newEventVC
            } else {
                let newHabitVC = NewHabitViewController(tracker: tracker, category: category)
                newHabitVC.recordsLabel.text = recordsString
                newHabitVC.updateUIForCurrentMode()
                viewController = newHabitVC
            }
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @objc func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if let blurEffectView = sender.view?.subviews.compactMap({ $0 as? UIVisualEffectView }).first {
                UIView.animate(withDuration: 0.3) {
                    blurEffectView.isHidden = false
                }
            }
        } else if sender.state == .ended || sender.state == .cancelled {
            if let blurEffectView = sender.view?.subviews.compactMap({ $0 as? UIVisualEffectView }).first {
                UIView.animate(withDuration: 0.3) {
                    blurEffectView.isHidden = true
                }
            }
        }
    }
    
    @objc private func datePickerChanged(sender: UIDatePicker) {
        if let currentDate = createDatePicker.date.deleteTime() {
            self.currentDate = currentDate
            trackerStore.updateDayOfWeekPredicate(for: currentDate)
            filters()
            applyFilters()
            trackerCollectionView.reloadData()
        }
    }
    
    @objc private func addTrackerButtonTapped() {
        trackerCollectionView.reloadData()
        let trackerCreator = TrackerCreatorViewController(delegate: self)
        trackerCreator.delegate = self
        trackerCreator.categories = categories
        trackerCreator.trackerStore = trackerStore
        let navigationController = UINavigationController(rootViewController: trackerCreator)
        present(navigationController, animated: true)
        analiticsService.report(event: "click", params: ["screen": "Main", "item": "add_track"])
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func filterButtonTapped() {
        let filterViewController = FilterViewController()
        filterViewController.delegate = self
        filterViewController.filters = [LocalizableStringKeys.allTrackers, LocalizableStringKeys.trackersForToday, LocalizableStringKeys.completed, LocalizableStringKeys.unfinished]
        
        let navigationController = UINavigationController(rootViewController: filterViewController)
        present(navigationController, animated: true, completion: nil)
        analiticsService.report(event: "click", params: ["screen": "Main", "item": "filter"])
    }
}

// MARK: TrackerCreatorDelegate
extension TrackerViewController: TrackerCreatorDelegate {
    func newTrackerCreated(_ tracker: Tracker, category: String?) {
        let newCategory = TrackerCategory(title: category ?? "Новая категория", trackers: [tracker])
        categories.append(newCategory)
        filters()
        trackerCollectionView.reloadData()
        dismiss(animated: true, completion: nil)
        updateCompletedTrackers()
        filterDataByDate()
        applyFilters()
    }
    
    func didSelectTrackerType(_ type: String) {
    }
}

// MARK: UICollectionViewDataSource
extension TrackerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return trackerStore.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trackerStore.numberOfRows(at: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.cellID, for: indexPath) as? TrackerCell
        else {
            return UICollectionViewCell()
        }
        if let tracker = trackerStore.cellData(at: indexPath) {
            if let dateWithoutTime = Date().deleteTime() {
                let resCompare = Calendar.current.compare(dateWithoutTime, to: currentDate, toGranularity: .day)
                let trackerRecordDate = completedTrackers.first { $0.id == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: currentDate) }
                let isTrackerDone = trackerRecordDate != nil
                
                let model = TrackerCellViewModel(name: tracker.name,
                                                 emoji: tracker.emoji,
                                                 color: tracker.color,
                                                 trackerIsDone: isTrackerDone,
                                                 doneButtonIsEnabled: resCompare == .orderedSame || resCompare == .orderedDescending,
                                                 counter:  UInt(completedTrackers.filter { $0.id == tracker.id }.count),
                                                 id: tracker.id)
                cell.configure(model: model)
                cell.isPinned = isTrackerPinned(tracker)
                cell.cellTapAction = { [weak self] in
                    self?.trackerCellDelegate(id: tracker.id)
                }
                let trackerViewInteraction = UIContextMenuInteraction(delegate: self)
                cell.trackerView.addInteraction(trackerViewInteraction)
                
                let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
                blurEffectView.frame = cell.bounds
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                blurEffectView.isHidden = true
                blurEffectView.isUserInteractionEnabled = false
                cell.trackerView.addSubview(blurEffectView)
                
                
                let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
                longPressGestureRecognizer.minimumPressDuration = 0.5
                cell.trackerView.addGestureRecognizer(longPressGestureRecognizer)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrackerHeader.header, for: indexPath) as? TrackerHeader
        else {
            return UICollectionReusableView()
        }
        let sectionTitle = trackerStore.titleForTrackerSection(section: indexPath.section)
        view.configure(headerText: sectionTitle)
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
        if let date = createDatePicker.date.deleteTime() {
            let record = TrackerRecord(id: id, date: date)
            if completedTrackers.contains(record) {
                trackerRecordStore.deleteTrackerRecord(record)
            } else {
                trackerStore.updateTrackerCoreData(value: record)
            }
            applyFilters()
        } else {
            return
        }
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

// MARK: TrackerStoreDelegate
extension TrackerViewController: TrackerStoreDelegate {
    func didUpdate() {
        updateCompletedTrackers()
        filterDataByDate()
        trackerCollectionView.reloadData()
        pictureStackView.isHidden = trackerStore.numberOfSections() > 0
    }
}


// MARK: TrackerViewControllerDataSource
extension TrackerViewController: TrackerViewControllerDataSource {
    func cellData(at indexPath: IndexPath) -> Tracker? {
        return trackerStore.cellData(at: indexPath)
    }
    
    func numberOfRows(at section: Int) -> Int {
        return trackerStore.numberOfRows(at: section)
    }
    
    func titleForTrackerSection(section: Int) -> String {
        return trackerStore.titleForTrackerSection(section: section)
    }
    
    func trackerStoreDidUpdate(_ trackerStore: TrackerStore) {
        trackerCollectionView.reloadData()
    }
}

extension TrackerViewController: UICollectionViewDelegate, UIContextMenuInteractionDelegate  {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell,
              let tracker = trackerStore.cellData(at: indexPath) else {
            return nil
        }
        cell.trackerView.tag = indexPath.row
        
        let trackerViewInteraction = UIContextMenuInteraction(delegate: self)
        cell.trackerView.addInteraction(trackerViewInteraction)
        
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { _ in
            let customActions = self.createCustomActions(id: tracker.id)
            return UIMenu(title: "", children: customActions)
        }
        
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let locationInCollectionView = interaction.location(in: trackerCollectionView)
        guard
            let indexPath = trackerCollectionView.indexPathForItem(at: locationInCollectionView),
            let tracker = trackerStore.cellData(at: indexPath)
        else {
            return nil
        }
        
        return UIContextMenuConfiguration (identifier: indexPath as NSCopying, previewProvider: nil) { _ in
            let customActions = self.createCustomActions(id: tracker.id)
            return UIMenu(title: "", children: customActions)
        }
    }
}

extension TrackerViewController: FilterViewControllerDelegate {
    func didSelectFilter(_ filters: String) {
        self.currentFilter = filters
        applyFilters()
        trackerCollectionView.reloadData()
    }
}

extension TrackerViewController {
    func isTrackerPinned(_ tracker: Tracker) -> Bool {
        return TrackerStore.shared.pinnedTrackers.contains(where:  { $0.id == tracker.id })
    }
}


