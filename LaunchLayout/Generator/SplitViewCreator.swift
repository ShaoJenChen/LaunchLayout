//
//  SplitViewCreator.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/9.
//

import Cocoa

enum SplitViewType: String {
    case MeetingGroups
    case CanvasEditor
    case ScreenLists
}

class SplitViewCreator {
    
    private let storyboard = NSStoryboard.main
    
    func createSplitView(with type: SplitViewType) -> NSSplitViewItem? {
            
        guard let viewController = self.storyboard?.instantiateController(withIdentifier: type.rawValue) as? NSViewController else { return nil }
        
        if type == .CanvasEditor { return NSSplitViewItem(viewController: viewController) }
        
        let sideBar = NSSplitViewItem(sidebarWithViewController: viewController)
        
        sideBar.minimumThickness = 200
        
        sideBar.maximumThickness = 200
        
        sideBar.collapseBehavior = .useConstraints
        
        return sideBar
    }
    
}
