//
//  ToDoListDetailsController.swift
//  TestToDoList
//
//  Created by user on 28.05.2025.
//

import UIKit

/// Контейнер для изменения задачи.
@MainActor
final class ToDoListDetailsModel {
    let id: String?
    var title: String
    var description: String
    var completed: Bool
    let createdAt: String?
    
    init(id: String?, title: String, description: String,
         completed: Bool, createdAt: String?) {
        self.id = id
        self.title = title
        self.description = description
        self.completed = completed
        self.createdAt = createdAt
    }
}

/// Изменённая задача.
struct ToDoListDetailsNewModel {
    let id: String?
    let title: String
    let description: String?
    let completed: Bool
}
/// Событие просмотра экрана задачи.
/// Изменение, создание, удаление.
enum ToDoListDetailsResult {
    case createOrUpdate(ToDoListDetailsNewModel)
    case delete(id: String)
}
final class ToDoListDetailsController: UIViewController {
    private let toDoListDetailsModel: ToDoListDetailsModel
    private let eventBlock: (ToDoListDetailsController, ToDoListDetailsResult) -> Void
    
    init(toDoListPreModel: ToDoListPreModelProtocol?,
         eventBlock: @escaping (ToDoListDetailsController, ToDoListDetailsResult) -> Void) {
        if let toDoListPreModel {
            let dateParser = ToDoDateFormatter(calendar: nil, dateFormats: [.HH, .colon, .mm, .space,
                                                                            .dd, .delim("/"),
                                                                            .MM, .delim("/"),
                                                                            .yyyy])
            self.toDoListDetailsModel = .init(id: toDoListPreModel.id,
                                              title: toDoListPreModel.title,
                                              description: toDoListPreModel.itemDescription ?? "",
                                              completed: toDoListPreModel.completed,
                                              createdAt: dateParser.string(from: toDoListPreModel.createdAt))
        } else {
            self.toDoListDetailsModel = .init(id: nil, title: "",
                                              description: "",
                                              completed: false, createdAt: nil)
        }
        self.eventBlock = eventBlock
        
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Задача"
        self.view.backgroundColor = UIColor.toDoDarkBackground
        
        let textField = UITextField()
        textField.addAction(UIAction(handler: { action in
            guard let textField = action.sender as? UITextField else { return }
            guard let `self` = textField.parentViewController(ofType: Self.self) else { return }
            
            self.toDoListDetailsModel.title = textField.text ?? ""
        }), for: .editingChanged)
        textField.placeholder = "Заголовок"
        textField.spellCheckingType = .no
        textField.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        textField.text = self.toDoListDetailsModel.title
        self.view.autoLayoutSubview(textField)
        textField.topEqualsToBorder(of: self.view.safeAreaLayoutGuide.topAnchor, space: 8)
        textField.leftRightEqualsToReadableMargin(of: self.view)
        
        let switcher = UISwitch(frame: .zero, primaryAction: UIAction(handler: { action in
            guard let switcher = action.sender as? UISwitch else { return }
            guard let `self` = textField.parentViewController(ofType: Self.self) else { return }
            
            self.toDoListDetailsModel.completed = switcher.isOn
        }))
        switcher.isOn = self.toDoListDetailsModel.completed
        self.view.autoLayoutSubview(switcher)
        switcher.topEqualsToBorder(of: textField.bottomAnchor, space: 12)
        switcher.leftEquals(to: textField)
        
        if let createdAt = self.toDoListDetailsModel.createdAt {
            let createdAtLabel = UILabel()
            createdAtLabel.textColor = UIColor.toDoGray
            createdAtLabel.font = ToDoListLayout.descriptionFont
            createdAtLabel.text = createdAt
            self.view.autoLayoutSubview(createdAtLabel)
            createdAtLabel.centerYEquals(to: switcher)
            createdAtLabel.rightEqualsToReadableMargin(of: self.view)
        }
        
        let textView = UITextView()
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.spellCheckingType = .no
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = UIColor.toDoWhite
        textView.text = self.toDoListDetailsModel.description
        textView.isScrollEnabled = false
        textView.delegate = self
        self.view.autoLayoutSubview(textView)
        textView.topEqualsToBorder(of: switcher.bottomAnchor, space: 12)
        textView.leftRightEquals(to: textField)
        
        let barButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction(handler: { action in
            guard let barButtonItem = action.sender as? UIBarButtonItem else { return }
            guard let `self` = barButtonItem.parentViewController(ofType: Self.self) else { return }
            
            let toDoListDetailsModel = self.toDoListDetailsModel
            let id = toDoListDetailsModel.id
            let newTitle = toDoListDetailsModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let newDescription = toDoListDetailsModel.description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if newTitle.isEmpty, newDescription.isEmpty, let id {
                self.eventBlock(self, .delete(id: id))
            } else {
                let newCompleted = toDoListDetailsModel.completed
                let newDescription = newDescription.isEmpty ? nil : newDescription
                self.eventBlock(self, .createOrUpdate(.init(id: id,
                                                            title: newTitle,
                                                            description: newDescription,
                                                            completed: newCompleted)))
            }
        }))
        self.navigationItem.rightBarButtonItem = barButtonItem
    }
}

extension ToDoListDetailsController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.toDoListDetailsModel.description = textView.text
    }
}
