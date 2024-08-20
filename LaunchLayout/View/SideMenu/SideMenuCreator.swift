//
//  SideMenuCreator.swift
//  ColorProWheelConsole
//
//  Created by 陳劭任 on 2021/11/29.
//

import Cocoa

class SideMenuCreator: MenuCreatorDelegate {

    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        
    func sideMenuViewController(delegate: SideMenuDelegate?) -> NSViewController? {
        
        guard let sideMenuViewController = self.storyboard.instantiateController(withIdentifier: "SideMenuViewController") as? SideMenuViewController else { return nil }
        
        sideMenuViewController.delegate = delegate

        guard let cavasEditorItem = self.createSingleViewMenuItem(itemName: "Canvas Editor",
                                                               id: "Canvas Editor") else { fatalError() }

        sideMenuViewController.menuSource = [cavasEditorItem]
        
        return sideMenuViewController
        
    }
    
    private func createSingleViewMenuItem(itemName: String, iconName: String = "", id: String) -> SideMenuItem? {

        guard let viewController = self.storyboard.instantiateController(withIdentifier: id) as? NSViewController else { return nil }

        let splitItemContentView = NSSplitViewItem(viewController: viewController)

        let iconImage = NSImage(named: iconName)
        
        return SideMenuItem(type: .NormalView,
                            title: itemName,
                            icon: iconImage,
                            mainView: splitItemContentView)

    }
    
}

class SideMenuRowView: NSTableRowView {
    override func draw(_ dirtyRect: NSRect) {
        if isSelected == true {
            NSColor(hex: 0x505B75).set()
            dirtyRect.insetBy(dx: 14, dy: 5).fill()
        }
    }
}
