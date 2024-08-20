//
//  TabItem.swift
//  TestCollectionView
//
//  Created by 陳劭任 on 2022/5/1.
//

import Cocoa

class TabItem: NSCollectionViewItem {

    @IBOutlet weak var tabName: NSTextField!
    
    @IBOutlet weak var trackingBackView: TrackingBackView!

    @IBOutlet weak var tabDeleteBtn: ItemDeleteBtn!
    
    var tabNameEditedCompletion: ((IndexPath, String) -> Void)?
    
    var tabDeleteAction: ((IndexPath) -> Void)?
    
    let selectedTabColor = NSColor(hex: 0xF0F4F7)
    
    let unselectedTabColor = NSColor.white
    
    private var hoverObservation: NSKeyValueObservation?
    
    private var hoverDeleteBtnObservation: NSKeyValueObservation?
    
    override var isSelected: Bool {
        didSet {
            
            super.isSelected = isSelected
            
            guard let backView = self.view as? ColoredView else { return }
            
            backView.backgroundColor = self.isSelected ? selectedTabColor : unselectedTabColor
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.tabDeleteBtn.isHidden = true
        
        self.setBackViewColor()
        
        self.setBackViewObservation()
        
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        guard let tabCollectionView = self.collectionView?.dataSource as? TabCollectionViewController else { return }
        
        tabCollectionView.clearSelectedInAllCanvasViews()
        
        if event.clickCount == 2 {
            print("double click TabItem")
            self.tabName.isEditable = true
            self.tabName.becomeFirstResponder()
        }
        
    }
    
    private func setBackViewColor() {
        
        guard let backView = self.view as? ColoredView else { return }
        
        backView.wantsLayer = true
        backView.layer?.cornerRadius = 8
        backView.layer?.maskedCorners = [.layerMaxXMinYCorner]
        
        backView.layer?.borderWidth = 0.1
        backView.layer?.borderColor = .black
        
    }
    
    private func setBackViewObservation() {
                
        self.hoverObservation = self.trackingBackView.observe(\.isHover, options: [.new]) { [weak self] tabTrackView, change in
            
            guard let self = self else { return }
            
            guard let isHover = change.newValue else { return }
            
            self.tabDeleteBtn.isHidden = !isHover
            
            guard let collectionView = self.collectionView else { return }
                        
            guard let canvasTabItems = collectionView.visibleItems().filter({ $0 != self }) as? [TabItem] else { return }
            
            canvasTabItems.forEach({ $0.tabDeleteBtn.isHidden = true })
            
        }
        
        self.hoverDeleteBtnObservation = self.trackingBackView.observe(\.hoverPoint, options: [.new]) { [weak self] tabTrackView, change in
            
            guard let self = self else { return }
            
            guard let hoverPoint = change.newValue else { return }
            
            let isHoverDeleteBtn = self.tabDeleteBtn.frame.contains(hoverPoint)
            
            self.tabDeleteBtn.setHover(isHoverDeleteBtn)
            
        }
        
    }
    
    @IBAction func deleteCanvas(_ sender: ItemDeleteBtn) {
        
        guard let tabIndexPath = self.collectionView?.indexPath(for: self) else { return }
                
        self.tabDeleteAction?(tabIndexPath)
        
    }
    
}

extension TabItem: NSTextFieldDelegate {
    
    func controlTextDidEndEditing(_ obj: Notification) {
        
        self.tabName.isEditable = false
        
        self.tabName.resignFirstResponder()
        
        guard let tabCollectionView = self.collectionView,
              let indexPath = tabCollectionView.indexPath(for: self) else { return }
        
        self.tabNameEditedCompletion?(indexPath, self.tabName.stringValue)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        
        guard let textField = obj.object as? NSTextField else { return }
        
        let limitLength = 20
                
        if textField.stringValue.count > limitLength {
            
            textField.stringValue = String(textField.stringValue.prefix(limitLength))
        }
        
    }
    
}
