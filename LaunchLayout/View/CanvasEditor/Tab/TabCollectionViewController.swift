//
//  TabCollectionViewController.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/5/19.
//

import Cocoa

protocol CanvasTabDelegate {
    
    func didSelect(canvasView: CanvasView)
    
}

class TabCollectionViewController: NSViewController {

    @IBOutlet weak var tabCollectionView: NSCollectionView!
    
    private var indexPathsOfItemsBeingDragged: Set<IndexPath>!
        
    var canvasTabDelegate: CanvasTabDelegate?
    
    var viewModel: (CanvasViewDataSource & CanvasViewDelegate)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.registerCollectionView()
        
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        if let contentSize = self.tabCollectionView.collectionViewLayout?.collectionViewContentSize {
            
            self.tabCollectionView.frame = NSRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
            
        }
        
    }

    internal func clearSelectedInAllCanvasViews() {
       
        guard let canvasViews = self.viewModel?.currentRecordCanvasViews() else { return }
        
        canvasViews.forEach({ $0.clearCurrentSelected() })
        
    }
    
    private func registerCollectionView() {
        
        self.tabCollectionView.register(TabItem.self,
                                        forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TabItem"))
        
        self.tabCollectionView.registerForDraggedTypes([.string])
        
        self.tabCollectionView.setDraggingSourceOperationMask(.move, forLocal: true)
        
    }
}

extension TabCollectionViewController: NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let canvasViews = self.viewModel?.currentRecordCanvasViews() else { return 0 }
        
        return canvasViews.count
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let tabItem = collectionView.makeItem(withIdentifier:
                                                NSUserInterfaceItemIdentifier(rawValue: "TabItem"),
                                              for: indexPath) as! TabItem
                
        guard let canvasViews = self.viewModel?.currentRecordCanvasViews() else { return tabItem }
        
        tabItem.tabName.stringValue = canvasViews[indexPath.item].name
                
        tabItem.tabNameEditedCompletion = { [weak self] (indexPath, newName) in
            
            self?.viewModel?.editCanvasName(of: indexPath.item, newName: newName)
            
        }
        
        tabItem.tabDeleteAction = { [weak self] (indexPath) in
            
            guard collectionView.numberOfItems(inSection: 0) > 1 else {
                
                AlertGenerator.launchAlertInMainThread(with: "Last canvas can't delete.")
                
                return
            }
            
            guard AlertGenerator.launchAlert(with: "Are you sure deleting this canvas?").rawValue == 1000 else { return }
            
            self?.viewModel?.removeCanvasFromCurrentRecord(index: indexPath.item) {
                
                guard let previousSelectedIndexPath = collectionView.selectionIndexPaths.first else { return }
                
                collectionView.reloadData()
                
                //刪除正在被選擇的Canvas Tab, 顯示選到前一個
                guard previousSelectedIndexPath != indexPath else {
                    
                    var beforeCurrentIndex = indexPath.item - 1
                                
                    if beforeCurrentIndex < 0 { beforeCurrentIndex = 0 }
                    
                    collectionView.selectItems(at: [IndexPath(item: beforeCurrentIndex, section: 0)],
                                               scrollPosition: .centeredHorizontally)
                    
                    guard let canvasViews = self?.viewModel?.currentRecordCanvasViews() else { return }
                    
                    guard 0 ..< canvasViews.count ~= beforeCurrentIndex else { return }
                    
                    let canvasView = canvasViews[beforeCurrentIndex]
                    
                    self?.canvasTabDelegate?.didSelect(canvasView: canvasView)
                    
                    return
                }
                
                //刪除的不是現在選擇的Tab, 重新計算刪除之後要顯示選到哪一個
                var newSelectIndexPath = IndexPath(item: previousSelectedIndexPath.item, section: 0)
                
                if previousSelectedIndexPath.item > indexPath.item { newSelectIndexPath.item -= 1 }
                
                collectionView.selectItems(at: [newSelectIndexPath], scrollPosition: .centeredHorizontally)
                
            }
            
        }
        
        let backView = tabItem.view as! ColoredView
        
        backView.backgroundColor = collectionView.selectionIndexPaths.contains(indexPath) ? tabItem.selectedTabColor : tabItem.unselectedTabColor
        
        return tabItem
    }
    
}

extension TabCollectionViewController: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
//        print("collectionView didSelectItemsAt \(indexPaths)")
                
//        NSAnimationContext.runAnimationGroup { (context) in
//            context.duration = 0.8
//            context.allowsImplicitAnimation = true
//            collectionView.scrollToItems(at: collectionView.selectionIndexPaths,
//                                         scrollPosition: .centeredHorizontally)
//        }
        
        guard let canvasViews = self.viewModel?.currentRecordCanvasViews() else { return }
        
        guard let indexPath = indexPaths.first else { return }
        
        let canvasView = canvasViews[indexPath.item]
        
        self.canvasTabDelegate?.didSelect(canvasView: canvasView)
        
        self.clearSelectedInAllCanvasViews()
    }
 
}

extension TabCollectionViewController {
    
    //Drag
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexes: IndexSet, with event: NSEvent) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        let pbItem = NSPasteboardItem()
        
//        NSLog("pasteboardWriterForItemAt \(indexPath)")
        
        pbItem.setString(String(indexPath.item), forType: .string)
        
        return pbItem
    }
    
    //Start Drag
    func collectionView(_ collectionView: NSCollectionView,
                        draggingSession session: NSDraggingSession,
                        willBeginAt screenPoint: NSPoint,
                        forItemsAt indexPaths: Set<IndexPath>) {
        
        self.indexPathsOfItemsBeingDragged = indexPaths
        
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        validateDrop draggingInfo: NSDraggingInfo,
                        proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
                        dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        
        if proposedDropOperation.pointee == NSCollectionView.DropOperation.on {
            proposedDropOperation.pointee = NSCollectionView.DropOperation.before
        }
//        print("proposedDropIndexPath \(proposedDropIndexPath.pointee.item)")

        return NSDragOperation.move
        
    }
    
    //Drop
    func collectionView(_ collectionView: NSCollectionView,
                        acceptDrop draggingInfo: NSDraggingInfo,
                        indexPath: IndexPath,
                        dropOperation: NSCollectionView.DropOperation) -> Bool {
        
        guard let indexPathDragged = self.indexPathsOfItemsBeingDragged.first else { return false }
        
        let toIndexPath =
        indexPathDragged.compare(indexPath) == .orderedAscending ?
        IndexPath(item: indexPath.item - 1, section: indexPath.section) :
        IndexPath(item: indexPath.item, section: indexPath.section)
        
        collectionView.moveItem(at: indexPathDragged, to: toIndexPath)
        
        self.viewModel?.rearrangedCanvasViews(from: indexPathDragged.item, to: toIndexPath.item)
        
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        draggingSession session: NSDraggingSession,
                        endedAt screenPoint: NSPoint,
                        dragOperation operation: NSDragOperation) {
        self.indexPathsOfItemsBeingDragged = nil
    }
    
}
