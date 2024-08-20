//
//  MeetingCollectionViewController.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/28.
//

import Cocoa

class MeetingCollectionViewController: NSViewController {
    
    @IBOutlet var meetingCollectionView: NSCollectionView!
    
    private var meetingRecordDataSource: MeetingRecordDataSource? {
        get {
            
            guard let meetingViewController = self.parent as? MeetingViewController else { return nil }
            
            return meetingViewController.meetingRecordDataSource
            
        }
    }
    
    private var meetingRecordDelegate: MeetingRecordDelegate? {
        get {
            
            guard let meetingViewController = self.parent as? MeetingViewController else { return nil }
            
            return meetingViewController.meetingRecordDelegate
            
        }
    }
    
    private var indexPathsOfItemsBeingDragged: Set<IndexPath>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.registerCollectionView()
        
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        
        self.meetingCollectionView.collectionViewLayout?.invalidateLayout()
        
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
    }
    
    private func registerCollectionView() {
        
        self.meetingCollectionView.register(MeetingItem.self,
                                            forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MeetingItem"))
        
        self.meetingCollectionView.registerForDraggedTypes([.string])
        
        self.meetingCollectionView.setDraggingSourceOperationMask(.move, forLocal: true)
    }
    
}

extension MeetingCollectionViewController: NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let meetingItem = collectionView.makeItem(withIdentifier:
                                                    NSUserInterfaceItemIdentifier(rawValue: "MeetingItem"),
                                                  for: indexPath) as! MeetingItem
        
        guard let meetingName = self.meetingRecordDataSource?.meetingNameOf(index: indexPath.item) else {
            return meetingItem
        }
        
        meetingItem.meetingName.stringValue = meetingName
        
        meetingItem.deleteItemCallBack = { [weak self] index in
            
            guard let self = self else { return }
            
            self.meetingRecordDelegate?.removeMeetingRecord(of: index)
            
        }
        
        meetingItem.selectIndexCallBack = { [weak self] index in
                        
            guard let meetingViewController = self?.parent as? MeetingViewController else { return }
 
            var selectedIndex: NSNumber?
            
            if let index = index { selectedIndex = NSNumber(value: index) }
            
            meetingViewController.selectedMeetingRecordIndex?.value = selectedIndex
            
        }
        
        meetingItem.duplicateRecordCallBack = { [weak self] index in
            
            guard let self = self else { return }
            
            self.meetingRecordDelegate?.duplicateMeetingRecord(by: index)
            
        }
        
        meetingItem.modifyMeetingNameCallBack = { [weak self] (index, newName) in
            
            guard let self = self else { return }
            
            self.meetingRecordDelegate?.modifyMeetingRecord(name: newName, of: index)
            
        }
        
        return meetingItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let numberOfRecord = self.meetingRecordDataSource?.numberOfMeetingRecord()
        else { return 0 }
        
        return numberOfRecord
        
    }
    
    //Drag
    //Only support scrolling in vertical direction
    func collectionView(_ collectionView: NSCollectionView,
                        viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind,
                        at indexPath: IndexPath) -> NSView {

        guard kind == "NSCollectionElementKindInterItemGapIndicator" else { return  NSView() }

        let view = collectionView.makeSupplementaryView(ofKind: kind,
                                                        withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GapIndicator"),
                                                        for: indexPath)
        return view
    }
    
}

extension MeetingCollectionViewController: NSCollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
        let width = collectionView.bounds.width - 30
        
        return CGSize(width: width, height: 40)
    }
    
}

extension MeetingCollectionViewController: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
        guard let meetingViewController = self.parent as? MeetingViewController else { return }
        
        guard let selectedIndex = indexPaths.first?.item else { return }
        
        meetingViewController.selectedMeetingRecordIndex?.value = NSNumber(value: selectedIndex)
        
    }
    
}

extension MeetingCollectionViewController {
    
    //Drag
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexes: IndexSet, with event: NSEvent) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        let pbItem = NSPasteboardItem()
                
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
        
        return NSDragOperation.move
        
    }
    
    //Drop
    func collectionView(_ collectionView: NSCollectionView,
                        acceptDrop draggingInfo: NSDraggingInfo,
                        indexPath: IndexPath,
                        dropOperation: NSCollectionView.DropOperation) -> Bool {
        
        guard let draggedIndexPath = self.indexPathsOfItemsBeingDragged.first else { return false }
        
        let toIndexPath =
        draggedIndexPath.compare(indexPath) == .orderedAscending ?
        IndexPath(item: indexPath.item - 1, section: indexPath.section) :
        IndexPath(item: indexPath.item, section: indexPath.section)
        
        collectionView.moveItem(at: draggedIndexPath, to: toIndexPath)
        
        self.meetingRecordDelegate?.rearrangedMeetingRecord(from: draggedIndexPath.item,
                                                              to: toIndexPath.item)
        
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        draggingSession session: NSDraggingSession,
                        endedAt screenPoint: NSPoint,
                        dragOperation operation: NSDragOperation) {
        self.indexPathsOfItemsBeingDragged = nil
    }
}
