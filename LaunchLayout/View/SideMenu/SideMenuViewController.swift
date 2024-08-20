//
//  SideMenuViewController.swift
//  ColorProWheelConsole
//
//  Created by 陳劭任 on 2021/11/25.
//

import Cocoa

protocol SideMenuDelegate {
    
    func selected(_ menuItem: SideMenuItem)
    
}

enum MenuItemType {
      
    case NormalView
    
}

struct SideMenuItem {
    
    var type: MenuItemType
    
    var title: String
    
    var icon: NSImage?
    
    var mainView: NSSplitViewItem?
        
}

class SideMenuViewController: NSViewController {

    var menuSource: [SideMenuItem]?
    
    var delegate: SideMenuDelegate?
    
    @IBOutlet weak var menuTableView: NSTableView!
   
    @IBOutlet weak var urlTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let _ = self.delegate as? RootSplitViewController else {
            fatalError("Side menu need delegate")
        }
        
        if self.menuTableView.selectedRowIndexes.isEmpty {
            
            self.menuTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            
        }
   
        self.urlTextField.font = NSFont(name: "OpenSans-Light", size: 13)
    
    }
    
}

extension SideMenuViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        guard let count = self.menuSource?.count else { return 0 }
        
        return count
    }
    
}

extension SideMenuViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let menuItem = self.menuSource?[row] else { return nil }
     
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SideMenuCell"), owner: nil) as! NSTableCellView
        
        cell.imageView?.image = menuItem.icon
        
        cell.textField?.stringValue = menuItem.title
        
        cell.textField?.font = NSFont(name: "OpenSans-Regular", size: 23)
        
        if menuItem.icon == nil {
            
            cell.imageView?.isHidden = true
            
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
                
        guard let menuItem = self.menuSource?[row] else { return 0.0 }
        
        switch menuItem.type {
        case .NormalView:
            return 43.0
        }
        
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        guard let _ = self.menuSource?[row] else { return false }
                
        return true
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {

        return SideMenuRowView()

    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView else { return }
        
        print("tableView select \(tableView.selectedRow)")
        
        guard  0 ..< self.menuSource!.count ~= tableView.selectedRow else { return }
        
        guard let menuItem = self.menuSource?[tableView.selectedRow] else { return }
        
        self.delegate?.selected(menuItem)
        
    }
    
    func selectionShouldChange(in tableView: NSTableView) -> Bool {

        guard let count = self.menuSource?.count else { return false }
        
        let shouldChange = 0 ..< count ~= tableView.clickedRow
        
        return shouldChange
                
    }
}
