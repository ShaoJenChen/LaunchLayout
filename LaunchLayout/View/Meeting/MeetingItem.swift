//
//  MeetingItem.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/28.
//

import Cocoa

typealias DeleteItemCallBack = (Int) -> Void
typealias SelectIndexCallBack = (Int?) -> Void
typealias DuplicateRecordCallBack = (Int) -> Void
typealias ModifyMeetingNameCallBack = (Int, String) -> Void

class MeetingItem: NSCollectionViewItem {

    @IBOutlet var meetingName: NSTextField!
    
    @IBOutlet var closeBtn: ItemDeleteBtn!
    
    var deleteItemCallBack: DeleteItemCallBack?
    
    var selectIndexCallBack: SelectIndexCallBack?
    
    var duplicateRecordCallBack: DuplicateRecordCallBack?
    
    var modifyMeetingNameCallBack: ModifyMeetingNameCallBack?
    
    private let selectedColor = NSColor(calibratedRed: 0.416, green: 0.541, blue: 0.647, alpha: 0.2)
    
    private let unselectedColor = NSColor.white
    
    private let selectedBorderColor = NSColor.clear
    
    private let unselectedBorderColor = NSColor.clear
    
    private let selectedBorderWidth: CGFloat = 2
    
    private let unselectedBorderWidth: CGFloat = 1
    
    private let cornerRadius: CGFloat = 10
    
    private var hoverObservation: NSKeyValueObservation?
    
    private var hoverCloseBtnObservation: NSKeyValueObservation?
    
    override var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            
            guard let backView = self.view as? TrackingBackView else { return }
            
            backView.layer?.backgroundColor = self.isSelected ? self.selectedColor.cgColor : self.unselectedColor.cgColor
            
            backView.layer?.borderColor = self.isSelected ? self.selectedBorderColor.cgColor : self.unselectedBorderColor.cgColor
            
            backView.layer?.borderWidth = self.isSelected ? self.selectedBorderWidth : self.unselectedBorderWidth
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.setBackViewColors()
        
        self.setBackViewObservation()
        
        self.meetingName.delegate = self
        
    }
    
    private func setBackViewColors() {
        
        guard let backView = self.view as? TrackingBackView else { return }
        
        backView.wantsLayer = true
        
        backView.layer?.backgroundColor = self.unselectedColor.cgColor
        
        backView.layer?.borderColor = self.unselectedBorderColor.cgColor
        
        backView.layer?.borderWidth = self.unselectedBorderWidth
        
        backView.layer?.cornerRadius = self.cornerRadius
        
    }
    
    private func setBackViewObservation() {
        
        guard let backView = self.view as? TrackingBackView else { return }
        
        self.hoverObservation = backView.observe(\.isHover, options: [.new]) { [weak self] meetingItemBackView, change in
            
            guard let self = self else { return }
            
            guard let isHover = change.newValue else { return }
            
            self.closeBtn.isHidden = !isHover
            
            guard let collectionView = self.collectionView else { return }
                        
            guard let meetingRecordItems = collectionView.visibleItems().filter({ $0 != self }) as? [MeetingItem] else { return }
            
            meetingRecordItems.forEach({ $0.closeBtn.isHidden = true })
            
        }
        
        self.hoverCloseBtnObservation = backView.observe(\.hoverPoint, options: [.new]) { [weak self] meetingItemBackView, change in
            
            guard let self = self else { return }
            
            guard let hoverPoint = change.newValue else { return }
            
            let isHoverOnCloseBtn = self.closeBtn.frame.contains(hoverPoint)
            
            self.closeBtn.setHover(isHoverOnCloseBtn)
            
        }
        
    }
    
    @IBAction func deleteBtnClicked(_ sender: ItemDeleteBtn) {
        
        guard AlertGenerator.launchAlert(with: "Are you sure deleting this meeting?").rawValue == 1000 else { return }
        
        guard let meetingCollectionView = self.collectionView,
              let selfIndexPath = meetingCollectionView.indexPath(for: self) else { return }
        
        if let currentSelectedIndexPath = meetingCollectionView.selectionIndexPaths.first,
           currentSelectedIndexPath == selfIndexPath {

            let precedingIndex = currentSelectedIndexPath.item - 1

            let followingIndex = currentSelectedIndexPath.item + 1
            
            let nextIndexPath = precedingIndex < 0 ? IndexPath(item: followingIndex, section: 0) : IndexPath(item: precedingIndex, section: 0)
            
            var nextIndex: Int?
            
            if let _ = meetingCollectionView.item(at: nextIndexPath) {
                
                meetingCollectionView.selectionIndexPaths = [nextIndexPath]
                
                nextIndex = nextIndexPath.item
                
            }
            
            self.selectIndexCallBack?(nextIndex)

        }
        
        self.deleteItemCallBack?(selfIndexPath.item)
        
        meetingCollectionView.deleteItems(at: [selfIndexPath])
        
    }
    
    @IBAction func duplicateMeetingRecord(_ sender: NSMenuItem) {
        
        guard let meetingCollectionView = self.collectionView,
              let selfIndexPath = meetingCollectionView.indexPath(for: self) else { return }
        
        self.duplicateRecordCallBack?(selfIndexPath.item)
        
        meetingCollectionView.insertItems(at: [selfIndexPath])
        
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        if event.clickCount == 2 {
            print("double click MeetingItem")
            
            self.meetingName.isEditable = true
            
            self.meetingName.becomeFirstResponder()
            
        }
        
    }
    
}

extension MeetingItem: NSTextFieldDelegate {
    
    func controlTextDidEndEditing(_ obj: Notification) {
        
        self.meetingName.isEditable = false
        
        self.meetingName.resignFirstResponder()
        
        guard let meetingRecordCollectionView = self.collectionView,
              let selfIndexPath = meetingRecordCollectionView.indexPath(for: self) else { return }
        
        self.modifyMeetingNameCallBack?(selfIndexPath.item, self.meetingName.stringValue)
    }
    
}
