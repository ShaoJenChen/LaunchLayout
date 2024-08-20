//
//  RootViewController.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/12.
//

import Cocoa

class RootViewController: NSViewController {

    @IBOutlet private var leftCollapseButton: CollapseButton!
    
    @IBOutlet private var rightCollapseButton: CollapseButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
    @IBAction func collapseSplitView(_ sender: CollapseButton) {
        
        guard let rootSplitViewController = self.children.first(where: {$0 is RootSplitViewController}) as? RootSplitViewController else { return }
        
        let position = sender.sideBarPosition.rawValue
        
        guard 0 ..< rootSplitViewController.splitViewItems.count ~= position else { return }
        
        rootSplitViewController.splitViewItems[position].animator().isCollapsed.toggle()
        
    }
    
}

extension RootViewController: SideBarIsCollapseDelegate {
    
    func collapsed(with isCollapsed: (isCollapsedLeft: Bool, isCollapsedRight: Bool)) {
        
        self.leftCollapseButton.isCollapsed = isCollapsed.isCollapsedLeft
        
        self.rightCollapseButton.isCollapsed = isCollapsed.isCollapsedRight
        
    }
    
}

class CollapseButton: VSTrackingBtn {
    
    private var hoverState: HoverState = .NotHover {
        
        didSet {
            
            let icons = self.sideBarPosition == .Left ? (NSImage(named: "MeetingCollapseHoverIcon"), NSImage(named: "MeetingCollpaseIcon")) : (NSImage(named: "ScreenCollapseHoverIcon"), NSImage(named: "ScreenCollapseIcon"))
            
            self.image = hoverState == .Hover ? icons.0 : icons.1

        }
        
    }
    
    var sideBarPosition: CollpaseSideBarPosition {
        
        get { return self.tag == 0 ? .Left : .Right }
        
    }
    
    var isCollapsed: Bool = false {
        
        didSet {
//            print("CollapseButton \(self.sideBarPosition) isCollapsed \(isCollapsed)")
        }
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.setDefaultState()
        
    }
    
    override func mouseMoved(with event: NSEvent) {
        
        self.hoverState = .Hover
        
    }
    
    override func mouseExited(with event: NSEvent) {
        
        self.hoverState = .NotHover
    }
    
    func setDefaultState() {
        
        self.hoverState = .NotHover

    }
    
}
