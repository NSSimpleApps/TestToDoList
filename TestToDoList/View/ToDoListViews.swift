//
//  ToDoListViews.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//


import UIKit

/// Шрифты.
struct ToDoListLayout {
    private init() {}
    
    static let titleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
    static let descriptionFont = UIFont.systemFont(ofSize: 12, weight: .regular)
}
/// Событие на ячейке задачи.
enum ToDoListCellEvent {
    case edit, share, delete
}

/// Взаимодействие ячейки при показе меню.
@MainActor
protocol ToDoListCellEventProtocol: AnyObject {
    func toDoListCell(_ toDoListCell: ToDoListCell, wantsPerformEvent toDoListCellEvent: ToDoListCellEvent)
}
/// Ячейка задачи.
class ToDoListCell: UITableViewCell, UIContextMenuInteractionDelegate {
    let leftImageView = UIImageView()
    let titleLabel = UILabel()
    let dateLabel = UILabel()
    
    weak var delegate: (any ToDoListCellEventProtocol)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        let contentView = self.contentView
        contentView.backgroundColor = .clear
        
        contentView.addInteraction(UIContextMenuInteraction(delegate: self))
        
        let imageSize: CGFloat = 24
        self.leftImageView.layer.borderWidth = 1
        self.leftImageView.layer.cornerRadius = imageSize / 2
        contentView.autoLayoutSubview(self.leftImageView)
        self.leftImageView.topEquals(to: contentView, inset: 12)
        self.leftImageView.leftEqualsToLayoutMargin(of: contentView)
        self.leftImageView.sizeEqualsTo(square: imageSize)
        
        self.titleLabel.font = ToDoListLayout.titleFont
        contentView.autoLayoutSubview(self.titleLabel)
        self.titleLabel.topEquals(to: self.leftImageView)
        self.titleLabel.leftEqualsToBorder(of: self.leftImageView.rightAnchor, space: 8)
        self.titleLabel.rightEqualsToLayoutMargin(of: contentView)
        
        let topBorder: NSLayoutYAxisAnchor
        
        if let toDoListDescriptionCell = self as? ToDoListDescriptionCellProtocol {
            let descriptionLabel = toDoListDescriptionCell.descriptionLabel
            descriptionLabel.font = ToDoListLayout.descriptionFont
            descriptionLabel.numberOfLines = 2
            contentView.autoLayoutSubview(descriptionLabel)
            descriptionLabel.topEqualsToBorder(of: self.titleLabel.bottomAnchor, space: 6)
            descriptionLabel.leftRightEquals(to: self.titleLabel)
            
            topBorder = descriptionLabel.bottomAnchor
        } else {
            topBorder = self.titleLabel.bottomAnchor
        }
        self.dateLabel.font = ToDoListLayout.descriptionFont
        self.dateLabel.textColor = UIColor.toDoGray
        contentView.autoLayoutSubview(self.dateLabel)
        self.dateLabel.topEqualsToBorder(of: topBorder, space: 6)
        self.dateLabel.leftRightEquals(to: self.titleLabel)
        self.dateLabel.bottomEquals(to: contentView, inset: 12)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        let menuAction: (UIAction, ToDoListCellEvent) -> Void = { action, toDoListCellEvent in
            let contextMenuInteraction = action.sender as? UIContextMenuInteraction
            guard let `self` = contextMenuInteraction?.delegate as? Self else { return }
            
            self.delegate?.toDoListCell(self, wantsPerformEvent: toDoListCellEvent)
        }
        
        let replyAction = UIAction(title: "Редактировать",
                                   image: UIImage(named: "edit-action")) { action in
            menuAction(action, .edit)
        }
        let shareAction = UIAction(title: "Поделиться",
                                   image: UIImage(named: "share-action")) { action in
            menuAction(action, .share)
        }
        let trashAction = UIAction(title: "Удалить",
                                   image: UIImage(named: "trash-action"),
                                   attributes: .destructive, handler: { action in
            menuAction(action, .delete)
        })
        let menuElements: [UIMenuElement] = [
            replyAction, shareAction, trashAction
        ]
        
        let menu = UIMenu(children: menuElements)
        return UIContextMenuConfiguration(actionProvider:  { actions -> UIMenu? in
            return menu
        })
    }
}
/// Протокол для ячеек с описанием задачи.
protocol ToDoListDescriptionCellProtocol: ToDoListCell {
    var descriptionLabel: UILabel { get }
}
/// Ячейка с описанием задачи.
final class ToDoListDescriptionCell: ToDoListCell, ToDoListDescriptionCellProtocol {
    let descriptionLabel = UILabel()
}
