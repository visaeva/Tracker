//
//  NewHabitViewController.swift
//  Tracker
//
//  Created by Victoria Isaeva on 26.09.2023.
//

import UIKit

protocol NewHabitViewControllerDelegate: AnyObject {
    func newTrackerCreated(_ tracker: Tracker)
}

final class NewHabitViewController: UIViewController, UITableViewDelegate {
    
    // MARK: - Public Properties
    var myCategories: [TrackerCategory] = []
    weak var delegate: NewHabitViewControllerDelegate?
    
    // MARK: - Private Properties
    private var mySchedule: Set<WeekDay> = []
    private var trackersScheduleViewController: TrackersSheduleViewController?
    private let tracker = false
    
    private let newHabitLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Новая привычка"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Введите название трекера"
        textField.clearButtonMode = .always
        textField.backgroundColor = UIColor(named: "Background")
        textField.layer.cornerRadius = 16
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        textField.returnKeyType = .done
        textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        return textField
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorInset = .init(top: 0, left: 20, bottom: 0, right: 20)
        tableView.rowHeight = 75
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 16
        return tableView
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(UIColor(named: "Red"), for: .normal)
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor(named: "Red")?.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(named: "BackgroundGray")
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let textFieldSymbolConstraintLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = .red
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var daysLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scheduleLabel: UILabel = {
        let label = UILabel()
        label.text = "Расписание"
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupHabitUI()
        setupHabitConstraints()
        
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textFieldSymbolConstraintLabel.isHidden = true
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Private Methods
    private func setupHabitUI() {
        view.addSubview(nameTextField)
        view.addSubview(tableView)
        view.addSubview(newHabitLabel)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        view.addSubview(textFieldSymbolConstraintLabel)
    }
    
    private func setupHabitConstraints() {
        NSLayoutConstraint.activate([
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameTextField.topAnchor.constraint(equalTo: newHabitLabel.bottomAnchor, constant: 24),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            newHabitLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            newHabitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 62),
            tableView.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            
            cancelButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            
            createButton.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
            createButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
            createButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            textFieldSymbolConstraintLabel.centerXAnchor.constraint(equalTo: nameTextField.centerXAnchor),
            textFieldSymbolConstraintLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
        ])
    }
    
    private func updateScheduleCellSubtitle() {
        if mySchedule.isEmpty {
            daysLabel.isHidden = true
            daysLabel.text = nil
        } else {
            let allDaysSelected = mySchedule.count == WeekDay.allCases.count
            if allDaysSelected {
                daysLabel.isHidden = false
                daysLabel.text = "Каждый день"
            } else {
                let selectedDays = mySchedule
                    .sorted(by: { $0.rawValue < $1.rawValue })
                    .map { WeekDay.shortNameDay(for: $0.rawValue) }
                daysLabel.isHidden = false
                daysLabel.text = selectedDays.joined(separator: ", ")
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func createButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        guard !mySchedule.isEmpty else {
            return
        }
        let newTracker = Tracker(id: UUID(),
                                 name: name,
                                 color: .orange,
                                 emoji: "❤️",
                                 mySchedule: mySchedule)
        
        delegate?.newTrackerCreated(newTracker)
        createButton.backgroundColor = .black
    }
    
    @objc private func textFieldDidChange() {
        if let text = nameTextField.text, text.count >= 38 {
            textFieldSymbolConstraintLabel.isHidden = false
        } else {
            textFieldSymbolConstraintLabel.isHidden = true
        }
    }
}
// MARK: UITableViewDataSource
extension NewHabitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") {
            cell.layer.masksToBounds = true
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Категория"
                cell.backgroundColor = UIColor(named: "Background")
                cell.layer.cornerRadius = 16
                cell.layer.maskedCorners = tracker ?
                [.layerMinXMinYCorner, .layerMaxXMinYCorner] :
                [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                
                if !tracker {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
                }
                cell.accessoryType = .disclosureIndicator
                
            case 1:
                cell.backgroundColor = UIColor(named: "Background")
                cell.layer.cornerRadius = 16
                cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 400)
                cell.accessoryType = .disclosureIndicator
                
                cell.contentView.addSubview(scheduleLabel)
                
                let calendar = Calendar.current
                let currentDay = calendar.component(.weekday, from: Date())
                cell.contentView.addSubview(daysLabel)
                
                let scheduleLabelTopConstraint = scheduleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10)
                let scheduleLabelLeadingConstraint = scheduleLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20)
                let daysLabelTopConstraint = daysLabel.topAnchor.constraint(equalTo: scheduleLabel.bottomAnchor, constant: 10)
                let daysLabelLeadingConstraint = daysLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20)
                let daysLabelBottomConstraint = daysLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10)
                
                if mySchedule.isEmpty {
                    daysLabel.isHidden = true
                    scheduleLabelTopConstraint.constant = 10
                    scheduleLabelLeadingConstraint.isActive = true
                    scheduleLabel.textAlignment = .left
                } else {
                    daysLabel.isHidden = false
                    scheduleLabelTopConstraint.constant = 0
                    scheduleLabelLeadingConstraint.isActive = false
                    scheduleLabel.textAlignment = .left
                }
                
                NSLayoutConstraint.activate([
                    scheduleLabelTopConstraint,
                    scheduleLabelLeadingConstraint,
                    daysLabelTopConstraint,
                    daysLabelLeadingConstraint,
                    daysLabelBottomConstraint])
                
            default:
                break
            }
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = .clear
            cell.layer.masksToBounds = true
            cell.layer.cornerRadius = 16
        }
        
        switch indexPath.row {
        case 0:
            let categoryVC = CategoryViewController()
            let navController = UINavigationController(rootViewController: categoryVC)
            present(navController, animated: true, completion: nil)
            
        case 1:
            if let exitingScheduleVC = trackersScheduleViewController {
                exitingScheduleVC.mySchedule = mySchedule
                exitingScheduleVC.delegate = self
                present(exitingScheduleVC, animated: true, completion: nil)
            } else {
                let scheduleVC = TrackersSheduleViewController(delegate: self, schedule: mySchedule)
                trackersScheduleViewController = scheduleVC
                present(scheduleVC, animated: true, completion: nil)
            }
        default:
            break
        }
    }
}

// MARK: TrackerSchedueViewControllerDelegate
extension NewHabitViewController: TrackerScheduleViewControllerDelegate {
    func selectDays(in schedule: Set<WeekDay>) {
        self.mySchedule = schedule
        updateScheduleCellSubtitle()
        dismiss(animated: true)
    }
}

// MARK: UITextFieldDelegate
extension NewHabitViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let range = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: range, with: string)
        
        if updatedText.count <= 38 {
            textFieldSymbolConstraintLabel.isHidden = true
            return true
        } else {
            textFieldSymbolConstraintLabel.isHidden = false
            return false
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textFieldSymbolConstraintLabel.isHidden = true
        return true
    }
}
