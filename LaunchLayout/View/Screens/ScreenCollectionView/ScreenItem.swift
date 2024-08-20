//
//  ScreenItem.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/8/12.
//

import Cocoa

class ScreenItem: NSCollectionViewItem {
   
    @IBOutlet weak var screenName: NSTextField!

    @IBOutlet weak var popUpBtn: NSPopUpButton!
    
    private let cornerRadius: CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.setBackViewColors()
        
    }
    
    private func setBackViewColors() {
                
        self.view.wantsLayer = true
        
        self.view.layer?.cornerRadius = self.cornerRadius
        
        self.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        self.view.layer?.borderColor = NSColor.clear.cgColor
        
        self.view.layer?.borderWidth = 0.6
        
    }

}
