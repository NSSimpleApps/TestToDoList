//
//  ToDoListViewController.swift
//  TestToDoList
//
//  Created by user on 26.05.2025.
//

import UIKit


/// Протокол view для списка задач.
@MainActor
protocol TodoListViewProtocol: UIViewController, Sendable {
    func display(toDoListModels: [ToDoListModel])
    func deleteToDoListModel(withId id: String)
    func update(toDoListModel: ToDoListModel)
    func insert(toDoListModel: ToDoListModel)
    func displayError()
}

/// Экран списка задач.
final class ToDoListController: UITableViewController, TodoListViewProtocol {
    private let presenter: ToDoListPresenterProtocol
    
    private let bottomTitleButtonItem = UIBarButtonItem(title: nil)
    private let debounceManager = DebounceManager()
    
    private var toDoListModels: [ToDoListModel] = []
    private var initialLoading = true
    private var searchString: String?
    
    init(presenter: any ToDoListPresenterProtocol) {
        self.presenter = presenter
        
        super.init(style: .grouped)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Задачи"
        self.navigationItem.largeTitleDisplayMode = .always
        let tableView = self.tableView!
        tableView.backgroundColor = UIColor.toDoDarkBackground
        tableView.separatorColor = UIColor.toDoDarkStroke
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(cellClass: ToDoListCell.self)
        tableView.register(cellClass: ToDoListDescriptionCell.self)
        
        let refreshControl = UIRefreshControl(frame: .zero, primaryAction: UIAction(handler: { action in
            guard let refreshControl = action.sender as? UIRefreshControl else { return }
            guard let self = refreshControl.parentViewController(ofType: Self.self) else { return }
            
            self.presenter.cancelAllOperations()
            self.presenter.loadToDoListModels(ignoreCache: true, searchString: self.searchString, todoListView: self)
        }))
        tableView.refreshControl = refreshControl
        
        let searchBar = UISearchBar()
        searchBar.placeholder = "Поиск"
        searchBar.sizeToFit()
        searchBar.delegate = self
        tableView.tableHeaderView = searchBar
        
        let createToDoListItemButton = UIBarButtonItem(systemItem: .compose, primaryAction: UIAction(handler: { action in
            guard let barButtonItem = action.sender as? UIBarButtonItem else { return }
            guard let `self` = barButtonItem.parentViewController(ofType: Self.self) else { return }
            
            self.presenter.displayToDoListModel(toDoListModel: nil, todoListView: self)
        }))
        
        self.bottomTitleButtonItem.isEnabled = false
        self.bottomTitleButtonItem.tintColor = UIColor.toDoWhite
        self.bottomTitleButtonItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 11, weight: .regular),
                                                           .foregroundColor: UIColor.toDoWhite],
                                                          for: .disabled)
        
        self.toolbarItems = [UIBarButtonItem.flexibleSpace(),
                             self.bottomTitleButtonItem,
                             UIBarButtonItem.flexibleSpace(),
                             createToDoListItemButton]
        if let navigationController = self.navigationController {
            navigationController.setToolbarHidden(false, animated: false)
        }
        
        self.presenter.loadToDoListModels(ignoreCache: false, searchString: self.searchString, todoListView: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.toDoListModels.count
        if count == 0 {
            if self.initialLoading {
                let activityIndicatorView = UIActivityIndicatorView(style: .medium)
                activityIndicatorView.color = UIColor.toDoWhite
                activityIndicatorView.startAnimating()
                
                tableView.backgroundView = activityIndicatorView
            } else {
                let emptyModelsLabel = UILabel()
                emptyModelsLabel.textColor = UIColor.toDoWhite
                emptyModelsLabel.textAlignment = .center
                emptyModelsLabel.text = "Список пуст"
                
                tableView.backgroundView = emptyModelsLabel
            }
        } else {
            tableView.backgroundView = nil
        }
        return count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let toDoListModel = self.toDoListModels[indexPath.row]
        let toDoListCell: ToDoListCell
        let completed = toDoListModel.completed
        
        if let description = toDoListModel.description {
            let toDoListDescriptionCell = tableView.dequeueReusableCell(withCellClass: ToDoListDescriptionCell.self, for: indexPath)
            toDoListDescriptionCell.descriptionLabel.textColor = completed ? UIColor.toDoGray : UIColor.toDoWhite
            toDoListDescriptionCell.descriptionLabel.text = description
            toDoListCell = toDoListDescriptionCell
        } else {
            toDoListCell = tableView.dequeueReusableCell(withCellClass: ToDoListCell.self, for: indexPath)
        }
        toDoListCell.delegate = self
        toDoListCell.titleLabel.attributedText = toDoListModel.title
        
        if completed {
            toDoListCell.leftImageView.image = UIImage(named: "todolist-completed")
            toDoListCell.leftImageView.tintColor = UIColor.toDoYellow
            toDoListCell.leftImageView.layer.borderColor = UIColor.toDoYellow.cgColor
        } else {
            toDoListCell.leftImageView.image = nil
            toDoListCell.leftImageView.tintColor = nil
            toDoListCell.leftImageView.layer.borderColor = UIColor.toDoDarkStroke.cgColor
        }
        toDoListCell.dateLabel.text = toDoListModel.createdAtString
        
        return toDoListCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.presenter.displayToDoListModel(toDoListModel: self.toDoListModels[indexPath.row],
                                            todoListView: self)
    }
    
    func display(toDoListModels: [ToDoListModel]) {
        self.initialLoading = false
        self.toDoListModels = toDoListModels
        self.tableView.refreshControl?.fixedEndRefreshing()
        self.tableView.reloadData()
        
        self.bottomTitleButtonItem.title = self.bottomTitle(count: toDoListModels.count)
    }
    
    func displayError() {
        let alertController = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel))
        self.present(alertController, animated: true)
    }
    
    func deleteToDoListModel(withId id: String) {
        if let row = self.toDoListModels.firstIndex(where: { toDoListModelElement in
            toDoListModelElement.id == id
        }) {
            if self.toDoListModels.count == 1 {
                self.toDoListModels.removeAll()
                self.tableView.reloadData()
                self.bottomTitleButtonItem.title = self.bottomTitle(count: self.toDoListModels.count)
            } else {
                self.toDoListModels.remove(at: row)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                }, completion: { _ in
                    self.bottomTitleButtonItem.title = self.bottomTitle(count: self.toDoListModels.count)
                })
            }
        }
    }
    func update(toDoListModel: ToDoListModel) {
        let id = toDoListModel.id
        if let row = self.toDoListModels.firstIndex(where: { toDoListModelElement in
            toDoListModelElement.id == id
        }) {
            self.toDoListModels[row] = toDoListModel
            self.tableView.performBatchUpdates({
                self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
            })
        }
    }
    func insert(toDoListModel: ToDoListModel) {
        if self.toDoListModels.isEmpty {
            self.toDoListModels = [toDoListModel]
            self.tableView.reloadData()
        } else {
            self.toDoListModels.insert(toDoListModel, at: 0)
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            })
        }
    }
    
    private func bottomTitle(count: Int) -> String? {
        if count == 0 {
            return nil
        } else {
            let cases = count.cases(locale: "ru")
            let postfix: String
            switch cases {
            case .nominative:
                postfix = "запись"
            case .genitive:
                postfix = "записи"
            case .plural:
                postfix = "записей"
            }
            return String(count) + " " + postfix
        }
    }
}
extension ToDoListController: ToDoListCellEventProtocol {
    func toDoListCell(_ toDoListCell: ToDoListCell, wantsPerformEvent toDoListCellEvent: ToDoListCellEvent) {
        guard let indexPath = self.tableView.indexPath(for: toDoListCell) else { return }
        
        let toDoListModel = self.toDoListModels[indexPath.row]
        
        switch toDoListCellEvent {
        case .edit:
            self.presenter.displayToDoListModel(toDoListModel: toDoListModel, todoListView: self)
        case .share:
            self.presenter.shareToDoListModel(toDoListModel: toDoListModel, todoListView: self)
        case .delete:
            self.presenter.deleteToDoListModel(withId: toDoListModel.id, todoListView: self)
        }
    }
}

extension ToDoListController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.showsCancelButton = false
        if searchBar.isFirstResponder {
            searchBar.endEditing(true)
        }
        
        self.debounceManager.cancelAllOperations()
        self.searchString = nil
        self.presenter.cancelAllOperations()
        self.presenter.loadToDoListModels(ignoreCache: false, searchString: self.searchString, todoListView: self)
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.debounceManager.schedule(timeInterval: 1,
                                      completion: { [weak self] in
            guard let self else { return }
            
            let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            self.searchString = searchText.isEmpty ? nil : searchText
            self.presenter.cancelAllOperations()
            self.presenter.loadToDoListModels(ignoreCache: false, searchString: self.searchString, todoListView: self)
        })
    }
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return self.initialLoading == false
    }
}

/// Предобработанная модель задачи.
struct ToDoListModel: @unchecked Sendable {
    let id: String
    let title: NSAttributedString
    let description: String?
    let completed: Bool
    let createdAt: Date
    let createdAtString: String
    
    init(toDoPreModel: ToDoListPreModelProtocol, toDoDateFormatter: ToDoDateFormatter) {
        let completed = toDoPreModel.completed
        let titleColor = completed ? UIColor.toDoGray : UIColor.toDoWhite
        var titleAttributes: [NSAttributedString.Key: Any] = [.font: ToDoListLayout.titleFont,
                                                              .foregroundColor: titleColor]
        if completed {
            titleAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            titleAttributes[.strikethroughColor] = titleColor
        }
        let createdAt = toDoPreModel.createdAt
        self.id = toDoPreModel.id
        self.title = NSAttributedString(string: toDoPreModel.title, attributes: titleAttributes)
        self.description = toDoPreModel.itemDescription
        self.completed = completed
        self.createdAt = createdAt
        self.createdAtString = toDoDateFormatter.string(from: createdAt)
    }
}
