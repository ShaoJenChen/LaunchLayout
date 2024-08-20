//
//  RootSplitViewController.swift
//  ColorProWheelConsole
//
//  Created by 陳劭任 on 2021/11/25.
//

import Cocoa

protocol CollapseSplitViewDelegate {
    
    func collapse(position: CollpaseSideBarPosition)
    
}

protocol SideBarIsCollapseDelegate: AnyObject {
    
    func collapsed(with isCollapsed: (isCollapsedLeft: Bool, isCollapsedRight: Bool))
    
}

enum CollpaseSideBarPosition: Int {
    
    case Left = 0
    
    case Right = 2
    
}

class RootSplitViewController: NSSplitViewController {
    
    private var splitViewCreator = SplitViewCreator()
    
    private var canvasViewModel: ViewModelProtocols = CanvasViewModel()
    
    private var isCollapseDelegate: SideBarIsCollapseDelegate? {
        
        guard let rootViewController = self.parent as? RootViewController else { return nil }
        
        return rootViewController
        
    }
    
    private var itemIsCollapsed: (Bool, Bool) = (false, false) {
        
        didSet {
            
            self.isCollapseDelegate?.collapsed(with: itemIsCollapsed)
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addSplitView(with: .MeetingGroups)
        
        self.addSplitView(with: .CanvasEditor)
        
        self.addSplitView(with: .ScreenLists)
        
    }
    
    private func addSplitView(with type: SplitViewType) {
        
        guard let splitViewItem = self.splitViewCreator.createSplitView(with: type) else { return }
        
        switch type {
        case .MeetingGroups:
            guard let meetingRecordView = splitViewItem.viewController as? MeetingViewController else { return }
            
            meetingRecordView.meetingRecordDataSource = self.canvasViewModel
            
            meetingRecordView.meetingRecordDelegate = self.canvasViewModel
            
            self.canvasViewModel.observeMeetingList(meetingRecordView.selectedMeetingRecordIndex)
            
        case .CanvasEditor:
            
            guard let canvasEditorView = splitViewItem.viewController as? CanvasEditorViewController else { return }

            canvasEditorView.viewModel = self.canvasViewModel
            
        case .ScreenLists:
            
            guard let screenListView = splitViewItem.viewController as? ScreenListViewController else { return }
            
            screenListView.viewModel = self.canvasViewModel
            
            self.canvasViewModel.observeScreenList(screenListView.selectedCanvasIndex)
            
        }
        
        self.addSplitViewItem(splitViewItem)
        
    }
    
    override func splitViewDidResizeSubviews(_ notification: Notification) {
        
        guard 0 ..< self.splitViewItems.count ~= CollpaseSideBarPosition.Left.rawValue,
        0 ..< self.splitViewItems.count ~= CollpaseSideBarPosition.Right.rawValue else { return }

        let leftItem = self.splitViewItems[CollpaseSideBarPosition.Left.rawValue]
        
        let rightItem = self.splitViewItems[CollpaseSideBarPosition.Right.rawValue]
        
        self.itemIsCollapsed = (leftItem.isCollapsed, rightItem.isCollapsed)
        
    }
    
    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        super.splitView(splitView, canCollapseSubview: subview)
        
        return false
    }
}

extension RootSplitViewController: CollapseSplitViewDelegate {
    
    func collapse(position: CollpaseSideBarPosition) {
        
        guard 0 ..< self.splitViewItems.count ~= position.rawValue else { return }
        
        self.splitViewItems[position.rawValue].animator().isCollapsed.toggle()
        
    }
    
}

class MainSplitView: NSSplitView {
    override func drawDivider(in rect: NSRect) {
        NSColor.clear.setFill()
        rect.fill()
    }
}
